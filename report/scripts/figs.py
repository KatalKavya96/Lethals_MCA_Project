# Run from report/:  python3 scripts/figs.py   (needs sim/*.vcd from 'sh sim/run_all.sh' and matplotlib)
import os,sys; sys.path.insert(0,os.path.dirname(__file__))
import vcd, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Rectangle
plt.rcParams.update({'font.family':'serif','font.serif':['DejaVu Serif'],'font.size':8,
    'axes.spines.top':False,'axes.spines.right':False,'pdf.fonttype':42})
HB='#2a78d6'; SH='#eb6834'; INK='#222222'; MUTED='#777777'; GRID='#dddddd'
MN={0:'NOP',1:'LD',2:'ST',3:'LDI',4:'ADD',15:'HLT'}
def save(fig,name):
    fig.savefig('figures/%s.pdf'%name,bbox_inches='tight'); fig.savefig('figures/%s.png'%name,dpi=300,bbox_inches='tight'); plt.close(fig)

# ---------- samples ----------
def samp(tb,inst,sig):
    P='tb_%s.%s.'%(tb,inst)
    s=vcd.parse('../sim/%s.vcd'%tb,['tb_%s.clk'%tb,'tb_%s.rst'%tb]+[P+x for x in sig])
    out=[]
    for x in s:
        d={a.split('.')[-1]:vcd.num(b) for a,b in x.items()}
        if d['rst']==0 and d.get('done')==0: out.append(d)
    return out
H=samp('harvard','h2',['i_addr','op','d_addr','mem_rd','mem_wr','acc','done'])
S=samp('shared','s2',['pc_val','state','m_addr','fetch_op','ir_op','mem_rd','mem_wr','acc','done'])
assert len(H)==16 and len(S)==27, (len(H),len(S))

# ---------- waveform drawer ----------
def wave(rows, n, fname, width=7.16, title_col=None, xmax=None):
    xmax=xmax or n
    fig,ax=plt.subplots(figsize=(width,0.28*len(rows)+0.45))
    hgt=0.6
    for r,(label,kind,vals,col) in enumerate(rows):
        y=len(rows)-1-r
        ax.text(-0.25,y+hgt/2,label,ha='right',va='center',fontsize=7.5,family='monospace',color=INK)
        if kind=='clk':
            xs=[];ys=[]
            for k in range(n):
                xs+= [k,k,k+0.5,k+0.5]; ys+=[y,y+hgt,y+hgt,y]
            xs.append(n); ys.append(y)
            ax.plot(xs,ys,color=INK,lw=0.8)
        elif kind=='bit':
            xs=[];ys=[]
            for k,v in enumerate(vals):
                yy=y+(hgt if v else 0); xs+=[k,k+1]; ys+=[yy,yy]
            ax.plot(xs,ys,color=col,lw=1.2,drawstyle='default')
            for k,v in enumerate(vals):
                if v: ax.add_patch(Rectangle((k,y),1,hgt,color=col,alpha=0.15,lw=0))
        else:  # bus: vals are text or (text,colour); kind 'busn' = never merge
            vals=[v if isinstance(v,tuple) else (v,col) for v in vals]
            k=0
            while k<n:
                j=k
                while kind=='bus' and j+1<n and vals[j+1]==vals[k]: j+=1
                x0,x1=k,j+1; e=0.12
                poly=[(x0,y+hgt/2),(x0+e,y+hgt),(x1-e,y+hgt),(x1,y+hgt/2),(x1-e,y),(x0+e,y)]
                txt,c=vals[k]
                fc=c if txt not in ('','-') else 'white'
                ax.add_patch(Polygon(poly,closed=True,fc=fc,ec=INK,lw=0.6,alpha=1))
                if txt not in ('','-'):
                    ax.text((x0+x1)/2,y+hgt/2,str(txt),ha='center',va='center',fontsize=6.3 if len(str(txt))<5 else 5.2,color=INK)
                k=j+1
    for k in range(xmax+1): ax.axvline(k,color=GRID,lw=0.4,zorder=0)
    if xmax>n:
        ax.text(n+0.4,len(rows)/2,'done after %d cycles (HALT)'%n,fontsize=8,color=MUTED,va='center')
    ax.set_xlim(-0.1,xmax+0.1); ax.set_ylim(-0.3,len(rows)-0.2)
    ax.set_yticks([]); ax.spines['left'].set_visible(False)
    ax.set_xticks([k+0.5 for k in range(xmax)]); ax.set_xticklabels([str(k+1) for k in range(xmax)],fontsize=6.5)
    ax.tick_params(axis='x',length=0); ax.set_xlabel('Clock cycle (counted from reset release)',fontsize=7.5)
    save(fig,fname)

LIGHTB='#cde2fb'; LIGHTO='#fbd9c9'; LIGHTG='#eeeeee'
n=len(H)
wave([('clk','clk',None,None),
      ('i_addr (PC)','busn',['%02X'%d['i_addr'] for d in H],LIGHTB),
      ('instruction','busn',[MN[d['op']] for d in H],LIGHTG),
      ('d_addr','busn',['%02X'%d['d_addr'] if (d['mem_rd'] or d['mem_wr']) else '' for d in H],LIGHTO),
      ('mem_rd','bit',[d['mem_rd'] for d in H],SH),
      ('mem_wr','bit',[d['mem_wr'] for d in H],SH),
      ('acc','bus',[str(d['acc']) for d in H],LIGHTG)], n,'wave_harvard',xmax=27)
n=len(S)
wave([('clk','clk',None,None),
      ('state','busn',[('F',LIGHTB) if d['state']==0 else ('E',LIGHTO) for d in S],None),
      ('instruction','busn',[((MN[d['fetch_op']] if d['state']==0 else MN[d['ir_op']]),LIGHTG) for d in S],None),
      ('m_addr','busn',[('%02X'%d['m_addr'],LIGHTB if d['state']==0 else LIGHTO) for d in S],None),
      ('PC','bus',['%02X'%d['pc_val'] for d in S],LIGHTB),
      ('mem_rd','bit',[d['mem_rd'] for d in S],SH),
      ('mem_wr','bit',[d['mem_wr'] for d in S],SH),
      ('acc','bus',[str(d['acc']) for d in S],LIGHTG)], n,'wave_shared')

# ---------- bus occupancy (P2) ----------
fig,ax=plt.subplots(figsize=(7.16,1.75))
rows=[('Harvard: instruction bus',[('F',d['op']) for d in H],HB),
      ('Harvard: data bus',[('D' if (d['mem_rd'] or d['mem_wr']) else '',d['op']) for d in H],SH),
      ('Shared: single port',[('F' if d['state']==0 else 'D',d['fetch_op'] if d['state']==0 else d['ir_op']) for d in S],None)]
for r,(lab,cells,c) in enumerate(rows):
    y=2-r
    for k,(t,op) in enumerate(cells):
        if not t: 
            ax.add_patch(Rectangle((k+0.04,y+0.12),0.92,0.76,fc='white',ec=GRID,lw=0.6)); continue
        col=HB if t=='F' else SH
        ax.add_patch(Rectangle((k+0.04,y+0.12),0.92,0.76,fc=col,ec='none'))
        ax.text(k+0.5,y+0.5,MN[op],ha='center',va='center',fontsize=5,color='white')
    ax.text(-0.3,y+0.5,lab,ha='right',va='center',fontsize=7.5)
ax.axvline(16,color=INK,lw=0.8,ls='--'); ax.text(16.15,2.95,'Harvard done (16)',fontsize=6.5,va='bottom')
ax.axvline(27,color=INK,lw=0.8,ls='--'); ax.text(26.85,2.95,'Shared done (27)',fontsize=6.5,va='bottom',ha='right')
ax.set_xlim(0,27.2); ax.set_ylim(0,3.3); ax.set_yticks([]); ax.spines['left'].set_visible(False)
ax.set_xticks([k+0.5 for k in range(27)]); ax.set_xticklabels([str(k+1) for k in range(27)],fontsize=6.5); ax.tick_params(axis='x',length=0)
ax.set_xlabel('Clock cycle',fontsize=7.5)
from matplotlib.patches import Patch
ax.legend(handles=[Patch(color=HB,label='instruction fetch'),Patch(color=SH,label='data access'),Patch(fc='white',ec=GRID,label='idle')],
          loc='upper center',bbox_to_anchor=(0.5,-0.28),ncol=3,frameon=False,fontsize=7)
save(fig,'bus_occupancy')

# ---------- cycle counts ----------
import numpy as np
progs=['P1 block copy','P2 array sum','P3 compute-heavy']; hv=[18,16,16]; sv=[31,27,20]; N=[18,16,16]; M=[13,11,4]
fig,ax=plt.subplots(figsize=(3.45,2.2))
x=np.arange(3); w=0.36
b1=ax.bar(x-w/2-0.01,hv,w,color=HB,label='Harvard'); b2=ax.bar(x+w/2+0.01,sv,w,color=SH,label='Shared baseline')
for b in list(b1)+list(b2): ax.text(b.get_x()+b.get_width()/2,b.get_height()+0.5,str(int(b.get_height())),ha='center',fontsize=7)
for i in range(3): ax.text(x[i],max(hv[i],sv[i])+4,'%.2f$\\times$'%(sv[i]/hv[i]),ha='center',fontsize=7.5,fontweight='bold')
ax.set_xticks(x); ax.set_xticklabels(progs,fontsize=7); ax.set_ylabel('Clock cycles (measured)'); ax.set_ylim(0,40)
ax.yaxis.grid(True,color=GRID,lw=0.5); ax.set_axisbelow(True)
ax.legend(frameon=False,fontsize=7,loc='upper right',ncol=2,bbox_to_anchor=(1,1.12))
save(fig,'cycles')

# ---------- speed-up model ----------
fig,ax=plt.subplots(figsize=(3.45,2.2))
f=np.linspace(0,1,50)
ax.plot(f,1+f,color=HB,lw=1.6,label='Fair baseline: $S = 1 + f$')
ax.plot([0,1],[2,2],color=MUTED,lw=1.2,ls='--',label='Always-EXEC baseline: $S = 2$')
fs=[m/n for m,n in zip(M,N)]; ss=[s/h for s,h in zip(sv,hv)]
ax.scatter(fs,ss,s=28,color=SH,zorder=3,edgecolor='white',lw=1,label='Measured (P1, P2, P3)')
for fi,si,l in zip(fs,ss,['P1','P2','P3']):
    ax.annotate(l,(fi,si),xytext=(-12 if l!='P3' else 6,6 if l=='P1' else -10 if l=='P2' else 4),textcoords='offset points',fontsize=7)
ax.set_xlabel('$f = M/N$ (fraction of instructions that access data memory)',fontsize=7)
ax.set_ylabel('Speed-up (cycles)'); ax.set_xlim(0,1.02); ax.set_ylim(0.9,2.15)
ax.yaxis.grid(True,color=GRID,lw=0.5); ax.set_axisbelow(True); ax.legend(frameon=False,fontsize=6.5,loc='lower right')
save(fig,'speedup')

# ---------- synthesis: logic outside the storage array ----------
fig,ax=plt.subplots(figsize=(3.45,1.9))
cats=['Controller','Instr. ROM\n(const.)','Decoder','PC, OUT, R/W,\nglue']
hvv=[384,39,15,131]; svv=[368,0,16,175]
x=np.arange(4)
b1=ax.bar(x-w/2-0.01,hvv,w,color=HB,label='Harvard (total 17,481)'); b2=ax.bar(x+w/2+0.01,svv,w,color=SH,label='Shared (total 17,471)')
for b in list(b1)+list(b2): ax.text(b.get_x()+b.get_width()/2,b.get_height()+6,str(int(b.get_height())) if b.get_height()>0 else 'in mem.',ha='center',fontsize=6.5 if b.get_height()>0 else 5.5)
ax.set_xticks(x); ax.set_xticklabels(cats,fontsize=6.5); ax.set_ylabel('Generic cells (Yosys)'); ax.set_ylim(0,470)
ax.yaxis.grid(True,color=GRID,lw=0.5); ax.set_axisbelow(True); ax.legend(frameon=False,fontsize=6.5,loc='upper right')
save(fig,'synth_logic')
