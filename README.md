# thirdrail

my opinionated rails template for hack club apps. i got tired of setting up the EXACT same stuff in every app, so now there's a robot that does it for me.

## usage

```bash
rails new myapp \
    --no-rc \
    --skip-kamal \
    --skip-jbuilder \
    --skip-javascript \
    --skip-hotwire \
    -m https://raw.githubusercontent.com/24c02/thirdrail/main/template.rb
```

or swap that URL for a path if you've cloned it locally.

when it asks if you blindly trust my judgement, say yes and it'll pick all the good defaults for you. or pick and choose! you can do whatever you want all the time forever :-)

## what you get

these are always installed:

- **jb** — json templates that aren't slow
- **pry-rails** — better console
- **awesome_print** — pretty prints objects
- **dotenv-rails** — loads `.env.development`
- also removes that annoying `allow_browser versions: :modern` thing

then it asks if you want:

| thing | what it does |
|-------|--------------|
| **vite** | real frontend bundling with hot reload. can add yarn + sass too. |
| **phlex** | views as ruby classes. it's good. |
| **hack club auth** | oauth with auth.hackclub.com. oidc by default, or api mode if you need to make server-side calls. |
| **user model** | `User` with `hca_id`, `email`, `name`, `is_admin`. sets up `current_user`, `signed_in?`, etc. |
| **airctiverecord** | airtable orm. you know the one. |
| **public_identifiable** | stripe-like public IDs (`usr_abc123`) without extra columns. uses hashid-rails. |
| **bonus stuff** | starter home/login pages with routes. only shows up if you have a user model. |

## env vars

put these in `.env.development`:

```bash
HACKCLUB_CLIENT_ID=...
HACKCLUB_CLIENT_SECRET=...
AIRTABLE_PAT=...  # if using airctiverecord
```

## hack club auth

go to [auth.hackclub.com](https://auth.hackclub.com), make an app, add this callback url:

```
http://localhost:3000/auth/hackclub/callback
```

(use your real domain in prod obviously)

### oidc vs api mode

oidc is the default and is probably what you want. api mode adds `HCAService` for when you need to hit the hca api from your server:

```ruby
HCAService.new(access_token).me
HCAService.new(access_token).check_verification(email: "zrl@hackclub.com")
```

## running it

```bash
cd myapp
bin/rails db:migrate    # if you made a user model
bin/vite dev            # if you're using vite (in another terminal)
bin/rails server
```

## files

```
thirdrail/
├── template.rb         # the main thing
├── vite.rb
├── phlex.rb
├── hack_club_auth.rb
├── user.rb
├── airctiverecord.rb
├── public_identifiable.rb
└── bonus_stuff.rb
```
