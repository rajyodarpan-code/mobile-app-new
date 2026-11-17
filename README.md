# Rajyo Darpan Publisher – Android Mobile App

This is the dedicated manual publishing mobile application for **Rajyo Darpan** (https://rajyodarpan.in).

## Key Features
- **100% Manual Publishing Flow**: No AI dependency or AI prompts.
- **Direct WordPress Compatibility**: Converts content to standard Gutenberg blocks (`<!-- wp:paragraph -->`, `<!-- wp:heading -->`, `<!-- wp:list -->`).
- **Media Upload with Automatic WebP Optimization**: Featured images are compressed and converted to WebP on the backend before linking to WordPress.
- **Custom Theme Controls**: Supports `_rajyo_breaking` (Breaking News) and `_rajyo_featured` (Homepage Hero).
- **SEO Integration**: Direct mapping to `rank_math_title`, `rank_math_description`, and `rank_math_focus_keyword`.
- **Scheduled Publishing**: Integration with the Laravel backend's publishing queue and scheduler.
- **Offline Drafts & Auto-save**: SQLite-backed local drafts to prevent any loss of news articles.

## Backend Endpoints Used
- `POST /api/v1/auth/login` (Sanctum Bearer Token)
- `GET /api/v1/analytics/mobile-summary` (Home Dashboard Counters)
- `GET /api/v1/articles` & `POST /api/v1/articles`
- `PUT /api/v1/articles/{uuid}` & `DELETE /api/v1/articles/{uuid}`
- `POST /api/v1/media/upload` (Featured image multipart upload)
- `GET /api/v1/platforms/{id}/categories` (Live WordPress categories)
- `GET /api/v1/platforms/{id}/tags` (Live WordPress tags)
- `POST /api/v1/articles/{uuid}/publish` (Immediate or scheduled WordPress dispatch)
- `POST /api/v1/articles/{uuid}/publish/retry/{job}` (Retry failed publishing jobs)
- `GET /api/v1/schedules/upcoming` & `DELETE /api/v1/schedules/{id}`

## Building the Release APK

1. Make sure Flutter SDK is installed and added to your system `PATH`.
2. Open terminal in this folder:
   ```bash
   cd "C:\Users\arnab\Videos\Rajyodarpan APP\rajyo_darpan_publisher"
   flutter pub get
   flutter build apk --release
   ```
3. Output file will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`
