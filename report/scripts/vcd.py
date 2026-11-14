import re
def parse(path, wanted):
    """wanted: list of full dotted names e.g. tb_harvard.h2.i_addr. Returns per-cycle samples
    (value just before each rising clk edge), keyed by name."""
    ids={}; scope=[]; clkid=None
    with open(path) as f: lines=f.read().split('\n')
    i=0
    while i<len(lines):
        l=lines[i].strip(); i+=1
        if l.startswith('$scope'): scope.append(l.split()[2])
        elif l.startswith('$upscope'): scope.pop()
        elif l.startswith('$var'):
            p=l.split(); code=p[3]; name='.'.join(scope+[p[4]])
            if name in wanted: ids.setdefault(code,[]).append(name)
            if name==wanted[0]: clkid=code
        elif l.startswith('$enddefinitions'): break
    cur={n:'x' for n in wanted}; samples=[]; prevclk='0'; snap=dict(cur)
    for l in lines[i:]:
        l=l.strip()
        if l.startswith('#'): snap=dict(cur); continue
        if not l or l.startswith('$'): continue
        if l[0] in 'bB':
            v,code=l[1:].split()
        else:
            v,code=l[0],l[1:]
        if code==clkid and v=='1' and prevclk=='0':
            samples.append(dict(snap))
        if code==clkid: prevclk=v
        for n in ids.get(code,[]): cur[n]=v
    return samples
def num(v):
    try: return int(v,2)
    except: return None
