import urllib.request, json
service="registry.docker.io"
scope="repository:library/debian:pull"
url=f"https://auth.docker.io/token?service={service}&scope={scope}"
resp=urllib.request.urlopen(url, timeout=20)
data=json.load(resp)
token=data["token"]
req=urllib.request.Request("https://registry-1.docker.io/v2/library/debian/manifests/bookworm-slim", headers={"Accept":"application/vnd.docker.distribution.manifest.list.v2+json","Authorization":"Bearer "+token})
resp=urllib.request.urlopen(req, timeout=20)
print(resp.getcode())
print(resp.getheader(Docker-Content-Digest))
body=resp.read().decode(utf-8)
obj=json.loads(body)
print(obj.get(mediaType))
print(len(obj.get(manifests,[])))
for m in obj.get(manifests,[])[:5]:
    print(m.get(platform), m.get(digest))
