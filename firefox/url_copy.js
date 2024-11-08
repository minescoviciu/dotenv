// ==UserScript==
// @name         URL Copier (Keyboard Shortcut)
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Copies the current URL to clipboard using Cmd+Shift+C (Mac) or Ctrl+Shift+C (Windows/Linux)
// @author       You
// @match        http://*/*
// @match        https://*/*
// @match        file:///*
// @grant        GM.setClipboard
// @grant        GM.notification
// @require      https://unpkg.com/hotkeys-js/dist/hotkeys.min.js
// @run-at       document-start
// @noframes
// ==/UserScript==

(function() {
    'use strict';
    
    // Enhanced toast styling with transition improvements
    let cssText = `
        .url-copier-toaster {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 12px 24px;
            border-radius: 8px;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            font-weight: 500;
            z-index: 999999;
            opacity: 0;
            transform: translateY(-20px);
            transition: opacity 0.2s ease, transform 0.2s ease;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            pointer-events: none;
            visibility: hidden;
        }

        .url-copier-toaster.show {
            opacity: 1;
            transform: translateY(0);
            visibility: visible;
        }

        .url-copier-toaster.update {
            transform: scale(1.05);
            transition: transform 0.1s ease;
        }

        .url-copier-toaster.update-complete {
            transform: scale(1);
            transition: transform 0.2s ease;
        }

        @media (prefers-color-scheme: dark) {
            .url-copier-toaster {
                background-color: #2c2c2c;
                color: #ffffff;
                border: 1px solid #404040;
            }
        }

        @media (prefers-color-scheme: light) {
            .url-copier-toaster {
                background-color: #ffffff;
                color: #1a1a1a;
                border: 1px solid #e5e5e5;
            }
        }
    `;

    let toaster;
    let toasterTimeout;
    let updateTimeout;
    let lastKeypressTime = 0;
    let keypressCount = 0;
    const DOUBLE_PRESS_DELAY = 1000;
  
    class ToastManager {
        constructor(element) {
            this.element = element;
            this.isVisible = false;
            this.queue = [];
            this.currentTimeout = null;
        }

        show(message, isUpdate = false) {
            if (this.currentTimeout) {
                clearTimeout(this.currentTimeout);
                this.currentTimeout = null;
            }

            const showToast = () => {
                this.element.textContent = message;
                
                if (this.isVisible && isUpdate) {
                    // Apply update animation
                    this.element.classList.add('update');
                    requestAnimationFrame(() => {
                        setTimeout(() => {
                            this.element.classList.remove('update');
                            this.element.classList.add('update-complete');
                            setTimeout(() => {
                                this.element.classList.remove('update-complete');
                            }, 200);
                        }, 100);
                    });
                } else {
                    this.element.classList.add('show');
                    this.isVisible = true;
                }

                this.currentTimeout = setTimeout(() => {
                    this.hide();
                }, 2000);
            };

            if (this.isVisible) {
                this.hide(() => showToast());
            } else {
                showToast();
            }
        }

        hide(callback) {
            this.element.classList.remove('show');
            this.isVisible = false;
            
            if (callback) {
                setTimeout(callback, 200); // Match the CSS transition duration
            }
        }
    }
  
    function initializeToaster() {
        const style = document.createElement('style');
        style.textContent = cssText;
        document.head.appendChild(style);

        toaster = document.createElement('div');
        toaster.className = 'url-copier-toaster';
        document.body.appendChild(toaster);
        
        return new ToastManager(toaster);
    }
  
    function extractJiraTicket(url) {
        const match = url.match(/SW-\d+/);
        return match ? match[0] : null;
    }

    function copyCurrentUrl(toastManager) {
        const currentUrl = window.location.href;
        try {
            GM.setClipboard(currentUrl);
            toastManager.show('URL copied to clipboard!');
        } catch (error) {
            console.error('Failed to copy URL:', error);
        }
    }
  
    function copyJiraUrl(toastManager) {
        const currentUrl = window.location.href;
        const jiraTicket = extractJiraTicket(currentUrl);
        if (jiraTicket) {
            try {
                GM.setClipboard(jiraTicket);
                toastManager.show('Ticket Number Copied', true);
            } catch (error) {
                console.error('Failed to copy Jira ticket:', error);
            }
        }
    }
  
    function initialize() {
        const toastManager = initializeToaster();
        
        function handleKeyPress() {
            const currentTime = Date.now();

            if (currentTime - lastKeypressTime > DOUBLE_PRESS_DELAY) {
                keypressCount = 0;
            }
            
            keypressCount++;
            lastKeypressTime = currentTime;

            if (keypressCount === 1) {
                copyCurrentUrl(toastManager);
            }
            if (keypressCount === 2) {
                copyJiraUrl(toastManager);
            }
        }

        hotkeys('command+shift+c, ctrl+shift+c', function(event) {
            event.preventDefault();
            handleKeyPress();
        });
    }
  
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize);
    } else {
        initialize();
    }
})();
