---
layout: default
title: GitHub Pages Setup
nav_order: 10
---

# GitHub Pages Setup Guide

This document explains how to deploy and maintain the Wellbeing Mapper documentation website using GitHub Pages.

## Overview

The documentation website is built using Jekyll and the Cayman theme, customized with South African colors to match the app's branding. It provides comprehensive documentation for both app users and developers.

## Files Structure

```
docs/
├── _config.yml              # Jekyll configuration
├── _layouts/
│   └── default.html         # Custom layout with navigation
├── index.md                 # Homepage
├── USER_GUIDE.md           # App user documentation
├── DEVELOPER_GUIDE.md      # Developer setup and API docs
├── API_REFERENCE.md        # Complete API reference
├── ARCHITECTURE.md         # App architecture overview
├── NOTIFICATION_FEATURE_SUMMARY.md  # Notification system docs
├── PRIVACY.md              # Privacy policy
├── README.md               # Documentation overview
├── ENCRYPTION_SETUP.md     # Security setup guide
├── SERVER_SETUP.md         # Backend configuration
├── FLOW_CHARTS.md          # User flows and diagrams
├── RESEARCH_FEATURES_SUMMARY.md  # Research tools overview
└── GITHUB_PAGES_SETUP.md   # This file
```

## GitHub Pages Configuration

### 1. Enable GitHub Pages

1. Go to your repository settings on GitHub
2. Scroll down to "Pages" section
3. Under "Source", select "Deploy from a branch"
4. Choose "main" branch and "/docs" folder
5. Click "Save"

### 2. Custom Domain (Optional)

If you want to use a custom domain:
1. Add a `CNAME` file to the docs folder with your domain name
2. Configure your DNS settings to point to GitHub Pages
3. Update the `url` setting in `_config.yml`

### 3. HTTPS

GitHub Pages automatically provides HTTPS for github.io domains and custom domains.

## Customization

### Navigation

The main navigation is defined in `_layouts/default.html`. To add new pages:

1. Create the markdown file with Jekyll frontmatter
2. Add the page to the navigation menu in the layout
3. Set the `nav_order` in the frontmatter to control ordering

### Content Updates

All documentation is written in Markdown with Jekyll frontmatter:

```yaml
---
layout: default
title: Page Title
nav_order: 5
---
```

## Local Development

To test the site locally:

```bash
# Install Jekyll (one time setup)
gem install bundler jekyll

# Navigate to docs folder
cd docs

# Create Gemfile if it doesn't exist
echo 'source "https://rubygems.org"' > Gemfile
echo 'gem "github-pages", group: :jekyll_plugins' >> Gemfile

# Install dependencies
bundle install

# Serve locally
bundle exec jekyll serve

# Visit http://localhost:4000
```

## Maintenance

### Adding New Documentation

1. Create new `.md` file in docs folder
2. Add Jekyll frontmatter with `layout: default`
3. Update navigation in `_layouts/default.html` if needed
4. Test locally before pushing

### Updating Existing Content

1. Edit the markdown files directly
2. Jekyll will automatically rebuild the site
3. Changes are live within minutes of pushing to GitHub

### Monitoring

- Check GitHub Pages status in repository settings
- Monitor build logs in the Actions tab
- Test all links periodically

## Troubleshooting

### Build Failures

1. Check the Actions tab for build errors
2. Verify all markdown files have proper frontmatter
3. Ensure no broken internal links
4. Check Jekyll syntax in `_config.yml`

### Missing Pages

1. Verify the file has `.md` extension
2. Check Jekyll frontmatter is present
3. Ensure the file is in the docs folder
4. Check for typos in navigation links

### Styling Issues

1. Verify CSS syntax in `_layouts/default.html`
2. Test responsive design on different screen sizes
3. Check browser console for errors

## SEO and Accessibility

The site includes:
- Semantic HTML structure
- Skip navigation links
- Alt text for images
- Responsive design
- Fast loading times
- Search engine friendly URLs

## Analytics (Optional)

To add Google Analytics:
1. Get your GA tracking ID
2. Add it to `_config.yml`:
   ```yaml
   google_analytics: UA-XXXXXXXX-X
   ```

## Contact

For technical issues with the documentation site:
- Create an issue in the GitHub repository
- Contact the development team
- Check GitHub Pages status page

---

*This documentation website showcases the Wellbeing Mapper app and provides comprehensive resources for users, developers, and researchers.*
