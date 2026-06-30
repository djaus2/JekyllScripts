@echo off
echo Updating documentation from Drafts project...

REM Copy markdown files to _docs for Jekyll processing (overwrites existing)
xcopy "C:\Users\david\source\repos\Drafts\docs\*.md" "c:\Folders\Source\repos\BlogSite\DJzBlog\_docs\" /Y

REM Copy images to docs as static files (overwrites existing)
xcopy "C:\Users\david\source\repos\Drafts\docs\*.png" "c:\Folders\Source\repos\BlogSite\DJzBlog\docs\" /Y

REM Add front matter to NEW files only (skips existing ones)
ruby scripts/add-frontmatter-smart.rb

REM Fix image paths to point to correct location (updates all files)
ruby scripts/fix-image-paths.rb

echo Documentation updated successfully!
echo.
echo Markdown files in _docs/ (will be processed as HTML):
dir "_docs" /B
echo.
echo Images in docs/ (static files):
dir "docs\*.png" /B
echo.
echo.
echo Ready to build: bundle exec jekyll serve
echo.
pause
