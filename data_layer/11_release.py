"""Render the release notes with the current numbers substituted, ready to paste."""
import os, re
WORK=os.path.dirname(os.path.abspath(__file__))
FR=os.path.join(WORK,"out","api","v1","fragments")
src=open(os.path.join(WORK,"RELEASE_NOTES_v1.0.0.md"),encoding="utf-8").read()
def sub(m):
    f=os.path.join(FR,m.group(1)+".html")
    return open(f,encoding="utf-8").read().strip() if os.path.exists(f) else m.group(0)
out=re.sub(r"\{\{(\w+)\}\}",sub,src)
out=out.split("---\n\n*Numbers marked")[0].rstrip()+"\n"
p=os.path.join(WORK,"RELEASE_NOTES_rendered.md")
open(p,"w",encoding="utf-8",newline="\n").write(out)
left=re.findall(r"\{\{(\w+)\}\}",out)
print(f"rendered -> {os.path.relpath(p,WORK)}")
print("unsubstituted placeholders:", left or "none")
