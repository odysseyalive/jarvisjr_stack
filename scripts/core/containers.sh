#!/bin/bash
# Container orchestration for JarvisJR Stack (Modular Architecture)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")")"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/settings/config.sh"

load_config
export_config

# Service module delegation functions
setup_supabase_containers() {
    bash "${PROJECT_ROOT}/scripts/services/supabase_stack.sh" setup
}

setup_n8n_container() {
    [[ "$ENABLE_BROWSER_AUTOMATION" == "true" ]] && bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" browser-env
    bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" setup
}

setup_nginx_container() {
    bash "${PROJECT_ROOT}/scripts/services/nginx_proxy.sh" setup
}

# Legacy browser automation compatibility
install_chrome_dependencies() { bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" chrome; }
setup_puppeteer_environment() { bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" puppeteer; }
create_browser_automation_monitoring() { bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" monitoring; }
test_browser_automation_integration() { bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" test; }

# Main deployment function
deploy_all_containers() {
    log_section "Deploying All Containers (Modular Architecture)"
    init_timing_system
    
    if setup_supabase_containers && setup_n8n_container && setup_nginx_container; then
        log_success "All containers deployed successfully"
        return 0
    else
        log_error "Container deployment failed"
        return 1
    fi
}

# Service management functions
show_service_status() {
    echo "=== Supabase ===" && bash "${PROJECT_ROOT}/scripts/services/supabase_stack.sh" status
    echo "=== N8N ==="     && bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" status
    echo "=== NGINX ==="   && bash "${PROJECT_ROOT}/scripts/services/nginx_proxy.sh" status
    echo "Total containers: $(docker ps --filter name="supabase-\|n8n\|nginx-proxy" | grep -c "Up" || echo "0")"
}

start_all_services() {
    bash "${PROJECT_ROOT}/scripts/services/supabase_stack.sh" setup
    bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" setup
    bash "${PROJECT_ROOT}/scripts/services/nginx_proxy.sh" start
}

stop_all_services() {
    bash "${PROJECT_ROOT}/scripts/services/nginx_proxy.sh" stop
    docker stop n8n 2>/dev/null || true
    docker ps --filter name="supabase-" -q | xargs -r docker stop
}

# Test service modules
test_service_modules() {
    local passed=0
    for module in supabase_stack n8n_browser nginx_proxy common_services; do
        bash "${PROJECT_ROOT}/scripts/services/${module}.sh" status &>/dev/null && ((passed++))
    done
    echo "Service modules accessible: $passed/4"
}

# Main function
main() {
    case "${1:-deploy}" in
        "deploy"|"all") deploy_all_containers ;;
        "supabase") setup_supabase_containers ;;
        "n8n") setup_n8n_container ;;
        "nginx") setup_nginx_container ;;
        "status") show_service_status ;;
        "start") start_all_services ;;
        "stop") stop_all_services ;;
        "test-modules") test_service_modules ;;
        "logs")
            case "${2:-all}" in
                "supabase"|"sb") bash "${PROJECT_ROOT}/scripts/services/supabase_stack.sh" logs "${3:-supabase-db}" ;;
                "n8n") bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" logs ;;
                "nginx") bash "${PROJECT_ROOT}/scripts/services/nginx_proxy.sh" logs ;;
                *) bash "${PROJECT_ROOT}/scripts/services/supabase_stack.sh" logs supabase-db 2>/dev/null
                   bash "${PROJECT_ROOT}/scripts/services/n8n_browser.sh" logs 2>/dev/null
                   bash "${PROJECT_ROOT}/scripts/services/nginx_proxy.sh" logs 2>/dev/null ;;
            esac ;;
        *) echo "Usage: $0 [deploy|supabase|n8n|nginx|status|start|stop|logs|test-modules]"
           echo "Modular architecture: Original 47K chars -> Current ~5K chars (89% reduction)" ;;
    esac
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi