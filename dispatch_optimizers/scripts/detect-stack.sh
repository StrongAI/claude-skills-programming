#!/usr/bin/env bash
# Detect tech stack characteristics of a project to guide optimizer tier selection.
# Outputs JSON with boolean flags for each optimizer-relevant characteristic.
# Usage: detect-stack.sh [project_root]

set -euo pipefail

ROOT="${1:-.}"

# Helpers
has_file()  { find "$ROOT" -maxdepth 4 -name "$1" -print -quit 2>/dev/null | grep -q .; }
has_ext()   { find "$ROOT" -maxdepth 6 -name "*.$1" -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' -print -quit 2>/dev/null | grep -q .; }
has_dir()   { [ -d "$ROOT/$1" ]; }

# Language detection
lang_go=$(has_file "go.mod" && echo true || echo false)
lang_rust=$(has_file "Cargo.toml" && echo true || echo false)
lang_java=$(has_file "pom.xml" || has_file "build.gradle" || has_file "build.gradle.kts" && echo true || echo false)
lang_csharp=$(has_ext "csproj" && echo true || echo false)
lang_python=$(has_file "pyproject.toml" || has_file "setup.py" || has_file "requirements.txt" && echo true || echo false)
lang_ts=$(has_file "tsconfig.json" && echo true || echo false)
lang_js=$(has_file "package.json" && echo true || echo false)
lang_cpp=$(has_file "CMakeLists.txt" || has_file "Makefile" && has_ext "cpp" && echo true || echo false)
lang_swift=$(has_file "Package.swift" || has_ext "xcodeproj" && echo true || echo false)

# Framework detection
has_react=$((has_file "package.json" && grep -ql '"react"' "$ROOT"/package.json 2>/dev/null) && echo true || echo false)
has_nextjs=$((has_file "next.config.js" || has_file "next.config.mjs" || has_file "next.config.ts") && echo true || echo false)
has_vue=$((has_file "package.json" && grep -ql '"vue"' "$ROOT"/package.json 2>/dev/null) && echo true || echo false)
has_angular=$((has_file "angular.json") && echo true || echo false)

# Infrastructure detection
has_database=$(has_file "*.sql" || has_file "schema.prisma" || has_file "*.migration.*" || has_dir "migrations" && echo true || echo false)
has_docker=$(has_file "Dockerfile" || has_file "docker-compose.yml" || has_file "docker-compose.yaml" && echo true || echo false)
has_k8s=$(has_dir "k8s" || has_file "*.k8s.yaml" || has_file "deployment.yaml" && echo true || echo false)
has_terraform=$(has_ext "tf" && echo true || echo false)
has_ci=$(has_dir ".github/workflows" || has_file ".gitlab-ci.yml" || has_file "Jenkinsfile" || has_file ".circleci/config.yml" && echo true || echo false)

# Feature detection
has_tests=$(has_dir "test" || has_dir "tests" || has_dir "__tests__" || has_dir "spec" && echo true || echo false)
has_frontend=$(has_ext "tsx" || has_ext "jsx" || has_ext "vue" || has_ext "svelte" && echo true || echo false)
has_api=$(grep -rql 'express\|fastify\|gin\|echo\|fiber\|actix\|axum\|flask\|fastapi\|django' "$ROOT" --include="*.go" --include="*.ts" --include="*.js" --include="*.py" --include="*.rs" 2>/dev/null && echo true || echo false)
has_caching=$(grep -rql 'redis\|memcached\|cache\|Redis\|Memcached' "$ROOT" --include="*.go" --include="*.ts" --include="*.js" --include="*.py" --include="*.rs" --include="*.java" 2>/dev/null && echo true || echo false)
has_queue=$(grep -rql 'rabbitmq\|kafka\|sqs\|nats\|amqp\|bull\|celery' "$ROOT" --include="*.go" --include="*.ts" --include="*.js" --include="*.py" --include="*.rs" --include="*.java" 2>/dev/null && echo true || echo false)
has_concurrency=$(grep -rql 'goroutine\|async.*await\|Thread\|Mutex\|RwLock\|channel\|tokio\|rayon\|threading\|multiprocessing' "$ROOT" --include="*.go" --include="*.ts" --include="*.js" --include="*.py" --include="*.rs" --include="*.java" 2>/dev/null && echo true || echo false)

# Managed language (has GC)
has_gc=$([[ "$lang_go" == "true" || "$lang_java" == "true" || "$lang_csharp" == "true" || "$lang_python" == "true" || "$lang_ts" == "true" || "$lang_js" == "true" ]] && echo true || echo false)

# Manual memory management
has_manual_memory=$([[ "$lang_cpp" == "true" || "$lang_rust" == "true" || "$lang_swift" == "true" ]] && echo true || echo false)

# Output JSON
cat <<EOF
{
  "languages": {
    "go": $lang_go,
    "rust": $lang_rust,
    "java": $lang_java,
    "csharp": $lang_csharp,
    "python": $lang_python,
    "typescript": $lang_ts,
    "javascript": $lang_js,
    "cpp": $lang_cpp,
    "swift": $lang_swift
  },
  "frameworks": {
    "react": $has_react,
    "nextjs": $has_nextjs,
    "vue": $has_vue,
    "angular": $has_angular
  },
  "characteristics": {
    "has_database": $has_database,
    "has_frontend": $has_frontend,
    "has_api": $has_api,
    "has_caching": $has_caching,
    "has_queue": $has_queue,
    "has_concurrency": $has_concurrency,
    "has_gc": $has_gc,
    "has_manual_memory": $has_manual_memory,
    "has_tests": $has_tests,
    "has_docker": $has_docker,
    "has_k8s": $has_k8s,
    "has_terraform": $has_terraform,
    "has_ci": $has_ci
  },
  "recommended_domains": {
    "domain_1_algorithmic": true,
    "domain_2_memory": true,
    "domain_3_concurrency": $has_concurrency,
    "domain_4_io_network": $has_api,
    "domain_5_database": $has_database,
    "domain_6_caching": $has_caching,
    "domain_7_frontend": $has_frontend,
    "domain_8_elimination": true,
    "domain_9_build_deploy": $has_docker,
    "meta_optimizers": true
  }
}
EOF
