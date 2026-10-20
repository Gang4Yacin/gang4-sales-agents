#!/usr/bin/env python3
"""Export en lecture seule des workflows n8n et de leur santé récente.

Usage :
    N8N_API_KEY=... python3 scripts/n8n_export.py --out /tmp/n8n-export [--ids id1,id2,...]

- Ne fait que des GET sur l'API publique n8n (/api/v1).
- La clé est lue dans la variable d'environnement N8N_API_KEY (jamais en argument, jamais écrite).
- Écrit dans --out (hors du repo par défaut) :
    workflows_all.json      tous les workflows (nœuds, connexions, settings)
    summary.tsv             id, actif, archivé, nom, déclencheurs, errorWorkflow, sauvegarde des succès
    executions/<id>.json    25 dernières exécutions des ids demandés (--ids), sinon des workflows actifs
Les fichiers exportés contiennent des secrets présents dans certains workflows : ne pas les commiter.
"""
import argparse, json, os, sys, urllib.parse, urllib.request

BASE = os.environ.get("N8N_BASE_URL", "https://n8n.srv882539.hstgr.cloud/api/v1")


def get(path, params=None):
    key = os.environ.get("N8N_API_KEY")
    if not key:
        sys.exit("N8N_API_KEY manquant (variable d'environnement)")
    url = f"{BASE}{path}" + ("?" + urllib.parse.urlencode(params) if params else "")
    req = urllib.request.Request(url, headers={"X-N8N-API-KEY": key, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def triggers(wf):
    out = []
    for n in wf.get("nodes", []):
        t = n.get("type", "").split(".")[-1]
        if "Trigger" in n.get("type", "") or t == "webhook":
            p = n.get("parameters", {})
            if t == "scheduleTrigger":
                rules = p.get("rule", {}).get("interval", [{}])
                out.append("cron " + "; ".join(r.get("expression") or json.dumps(r, ensure_ascii=False) for r in rules))
            elif t == "webhook":
                out.append("webhook")  # chemin volontairement omis
            else:
                out.append(t)
    return ", ".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/tmp/n8n-export")
    ap.add_argument("--ids", default="", help="ids de workflows séparés par des virgules")
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "executions"), exist_ok=True)

    wfs, cursor = [], None
    while True:
        params = {"limit": 250, "excludePinnedData": "true"}
        if cursor:
            params["cursor"] = cursor
        page = get("/workflows", params)
        wfs += page.get("data", [])
        cursor = page.get("nextCursor")
        if not cursor:
            break
    json.dump(wfs, open(os.path.join(a.out, "workflows_all.json"), "w"), ensure_ascii=False)

    with open(os.path.join(a.out, "summary.tsv"), "w") as f:
        f.write("id\tactive\tarchived\tname\ttriggers\terrorWorkflow\tsaveSuccess\n")
        for w in sorted(wfs, key=lambda x: (not x.get("active"), x["name"])):
            st = w.get("settings", {})
            f.write("\t".join([w["id"], str(w.get("active")), str(w.get("isArchived", False)), w["name"],
                               triggers(w), st.get("errorWorkflow", ""), st.get("saveDataSuccessExecution", "all")]) + "\n")

    ids = [i for i in a.ids.split(",") if i] or [w["id"] for w in wfs if w.get("active")]
    for wid in ids:
        ex = get("/executions", {"workflowId": wid, "limit": 25})
        json.dump(ex, open(os.path.join(a.out, "executions", f"{wid}.json"), "w"))
    print(f"{len(wfs)} workflows ({sum(1 for w in wfs if w.get('active'))} actifs), "
          f"exécutions exportées pour {len(ids)} ids -> {a.out}")


if __name__ == "__main__":
    main()
