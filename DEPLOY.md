# Deploying the portfolio

Two stages, on purpose.

**Stage 1 — GitHub Pages, today.** Free, HTTPS included, live in ten minutes. You can put the
URL on applications this week.

**Stage 2 — S3 + CloudFront + Terraform, week 10.** Costs about $1/month and takes a weekend.
Worth doing not because Pages is inadequate — it isn't — but because *the site becomes a
project*. "I migrated my site to S3 behind CloudFront, provisioned with Terraform, deployed by
a GitHub Actions pipeline, and cut TTFB from X to Y" is a better interview answer than having
started there.

Do them in that order. A live site today beats a perfect site in three weeks.

---

## Stage 1 — GitHub Pages

### 1. Repository

The repo must be named `<your-username>.github.io` to be served at the root domain. Any other
name is served under a subpath, which looks worse on a resume.

```bash
cd portfolio
git init
git add .
git commit -m "Portfolio site"
git branch -M main
gh repo create KrIShnA-768.github.io --public --source=. --remote=origin --push
```

Check your commit identity first, or this lands under the wrong name:

```bash
git config user.email
```

### 2. Move the workflow

The workflow is at `portfolio/.github/workflows/deploy-pages.yml`. If the portfolio is the
repository root, that path is already correct. If you nest it inside another repo, the
workflow must live at the **repository** root — `.github/` is only recognised there.

### 3. Enable Pages

Repository → Settings → Pages → Build and deployment → Source: **GitHub Actions**.

Not "Deploy from a branch". Without this the workflow runs green and publishes nothing, which
is a confusing ten minutes.

### 4. Push and watch

```bash
git push
```

Actions tab → `deploy-pages`. On success the deploy job prints the URL:
`https://KrIShnA-768.github.io`

**If the build fails on the placeholder check**, that is the workflow working as designed —
replace the placeholders in `index.html` (see README.md) and push again.

### 5. Custom domain, when you have one

1. Put your bare hostname in `CNAME` — just `krishna.dev`, nothing else in the file
2. At your registrar, create:
   - `A` records for the apex: `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - `CNAME` for `www` → `KrIShnA-768.github.io`
3. Settings → Pages → Custom domain → enter it → wait for the check to pass
4. Tick **Enforce HTTPS** once the certificate is issued (can take an hour)
5. Update `canonical`, `og:url`, `robots.txt` and `sitemap.xml` to the real domain

Those apex IPs are GitHub's and they do change occasionally — check GitHub's Pages docs rather
than trusting this file if the domain does not resolve.

---

## Stage 2 — S3 + CloudFront + Terraform

`terraform/` holds this. It is written as guided TODOs in the same style as the main project,
because the point is to build it, not to run someone else's module.

### Architecture

```
Route 53  ->  CloudFront  ->  S3 (private, OAC)
                   |
                ACM cert (us-east-1)
```

The S3 bucket stays **private**. CloudFront reaches it through Origin Access Control, so the
bucket is never public — which is both the correct pattern and a question you may be asked,
since the old tutorials all use public buckets and website endpoints.

### Three things that catch people out

1. **The ACM certificate must be in `us-east-1`**, regardless of where your bucket is.
   CloudFront is global and only reads certificates from that region. A cert in `ap-south-1`
   silently will not attach.
2. **S3 has no concept of a directory index behind CloudFront.** `example.com/about/` returns
   a 403, not `about/index.html`. Fix it with a CloudFront Function, or keep the site flat as
   it is now — flat avoids the problem entirely.
3. **CloudFront caches, including your mistakes.** Deploys need an invalidation, or you ship a
   fix and see the old page for 24 hours. The workflow in the TODOs does
   `aws cloudfront create-invalidation` after each sync. The first 1,000 invalidation paths per
   month are free; `/*` counts as one path.

### Cost

| | |
|---|---|
| S3 storage and requests | pennies |
| CloudFront | 1 TB/month free tier, then ~$0.085/GB |
| Route 53 hosted zone | $0.50/month |
| ACM certificate | free |

Realistically **under $1/month** for a portfolio. The only way to get a surprise bill is to
serve large files to real traffic, which is not going to happen here.

### Deploy pipeline

Replace the Pages workflow with:

```yaml
- aws s3 sync . s3://$BUCKET --delete \
    --exclude ".git/*" --exclude "terraform/*" --exclude "*.md"
- aws cloudfront create-invalidation --distribution-id $DIST --paths "/*"
```

Authenticate with the same GitHub OIDC role pattern as the main project — no stored AWS keys.
If you have already done it once there, this takes ten minutes.

### Then update the site

Change the footer line to say how it is hosted, and add the migration to the Projects section
with the before/after numbers. Measure TTFB with `curl -w "%{time_starttransfer}\n" -o /dev/null -s <url>`
before and after, from the same machine, so the number means something.

---

## Which to use when

| | GitHub Pages | S3 + CloudFront |
|---|---|---|
| Cost | free | ~$1/month |
| Setup | 10 minutes | a weekend |
| HTTPS | automatic | ACM, manual |
| Custom domain | yes | yes |
| Demonstrates DevOps skill | no | **yes** |
| Good enough for a portfolio | **yes** | yes |

Pages is genuinely fine. The migration is for your resume, not for the website — be honest
about that if someone asks, because pretending a one-page static site needed a CDN is worse
than saying "I did it to learn CloudFront, OAC and cache invalidation properly."
