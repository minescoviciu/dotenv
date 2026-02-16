// ==UserScript==
// @name         Simple Jenkins URL Transformer
// @namespace    http://tampermonkey.net/
// @version      1.6
// @description  Open Jenkins classic build page with Cmd+E/Ctrl+E and auto-link SW-/PR- tickets on supported pages
// @author       You
// @match        https://*.dev.drivenets.net/*
// @match        https://github.com/*
// @require      https://unpkg.com/hotkeys-js/dist/hotkeys.min.js
// @run-at       document-start
// @noframes
// ==/UserScript==

(function() {
    'use strict';

    const JIRA_BASE_URL = 'https://drivenets.atlassian.net/browse/';
    const GITHUB_PR_BASE_URL = 'https://github.com/drivenets/cheetah/pull/';
    const TICKET_LINK_STYLE_ID = 'sw-ticket-link-style';
    const SW_TICKET_REGEX = /\bSW-\d+\b/g;
    const PR_TICKET_REGEX = /\bPR-(\d+)\b/g;
    let linkObserver = null;
    let activeLinkers = [];

    function transformJenkinsUrl() {
        const currentUrl = window.location.href;

        if (!currentUrl.includes('/blue/organizations/jenkins/')) {
            return;
        }

        try {
            const url = new URL(currentUrl);
            const pathSegments = url.pathname.split('/');
            const blueIndex = pathSegments.indexOf('blue');

            if (blueIndex === -1) {
                return;
            }

            const encodedProject = pathSegments[blueIndex + 3];
            const prNumber = pathSegments[blueIndex + 5];
            const buildNumber = pathSegments[blueIndex + 6];

            if (!encodedProject || !prNumber || !buildNumber) {
                return;
            }

            const projectPath = decodeURIComponent(encodedProject).split('/');
            const newPathSegments = projectPath.map((segment) => `job/${segment}`).join('/');
            const newUrl = `${url.origin}/${newPathSegments}/job/${prNumber}/${buildNumber}/`;

            window.open(newUrl, '_blank');
        } catch (error) {
            console.error('Failed to transform URL:', error);
        }
    }

    function isGithubPage() {
        return window.location.hostname === 'github.com';
    }

    function isJenkinsPage() {
        return /^jenkins-[^.]+\..+$/.test(window.location.hostname);
    }

    function createTicketLink(label, href, datasetKey) {
        const link = document.createElement('a');
        link.href = href;
        link.textContent = label;
        link.className = 'sw-ticket-link';
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.dataset[datasetKey] = 'true';
        return link;
    }

    function createJiraLink(ticket) {
        return createTicketLink(ticket, `${JIRA_BASE_URL}${ticket}`, 'swTicketLink');
    }

    function createGithubPrLink(prTicket, prNumber) {
        return createTicketLink(prTicket, `${GITHUB_PR_BASE_URL}${prNumber}`, 'prTicketLink');
    }

    function ensureTicketLinkStyles() {
        if (document.getElementById(TICKET_LINK_STYLE_ID)) {
            return;
        }

        const style = document.createElement('style');
        style.id = TICKET_LINK_STYLE_ID;
        style.textContent = `
            a.sw-ticket-link {
                color: #0969da;
                background: rgba(9, 105, 218, 0.08);
                border: 1px solid rgba(9, 105, 218, 0.12);
                border-radius: 3px;
                padding: 0 2px;
                text-decoration: none;
            }

            a.sw-ticket-link:hover {
                color: #0550ae;
                background: rgba(9, 105, 218, 0.12);
                border-color: rgba(9, 105, 218, 0.2);
                text-decoration: underline;
            }

            @media (prefers-color-scheme: dark) {
                a.sw-ticket-link {
                    color: #58a6ff;
                    background: rgba(88, 166, 255, 0.12);
                    border-color: rgba(88, 166, 255, 0.22);
                }

                a.sw-ticket-link:hover {
                    color: #79c0ff;
                    background: rgba(88, 166, 255, 0.16);
                    border-color: rgba(88, 166, 255, 0.28);
                }
            }
        `;

        document.head.appendChild(style);
    }

    const LINKERS = [
        {
            isEnabled: isGithubPage,
            regex: SW_TICKET_REGEX,
            createLink(match) {
                return createJiraLink(match[0]);
            }
        },
        {
            isEnabled: isJenkinsPage,
            regex: PR_TICKET_REGEX,
            createLink(match) {
                return createGithubPrLink(match[0], match[1]);
            }
        }
    ];

    function getActiveLinkers() {
        return LINKERS.filter((linker) => linker.isEnabled());
    }

    function canProcessTextNode(textNode) {
        const parentElement = textNode.parentElement;
        if (!parentElement) {
            return false;
        }

        return !parentElement.closest('a, script, style, textarea, [contenteditable="true"]');
    }

    function findTextMatches(text, linkers) {
        const matches = [];

        linkers.forEach((linker) => {
            linker.regex.lastIndex = 0;
            let match;

            while ((match = linker.regex.exec(text)) !== null) {
                matches.push({
                    start: match.index,
                    end: match.index + match[0].length,
                    match,
                    linker
                });
            }
        });

        matches.sort((first, second) => first.start - second.start || second.end - first.end);

        const nonOverlappingMatches = [];
        let lastEnd = -1;

        matches.forEach((entry) => {
            if (entry.start >= lastEnd) {
                nonOverlappingMatches.push(entry);
                lastEnd = entry.end;
            }
        });

        return nonOverlappingMatches;
    }

    function textHasMatches(text, linkers) {
        return linkers.some((linker) => {
            linker.regex.lastIndex = 0;
            return linker.regex.test(text);
        });
    }

    function replaceTextNodeWithLinks(textNode, linkers) {
        const text = textNode.nodeValue;
        if (!text) {
            return;
        }

        const matches = findTextMatches(text, linkers);
        if (matches.length === 0) {
            return;
        }

        const fragment = document.createDocumentFragment();
        let lastIndex = 0;

        matches.forEach((entry) => {
            if (entry.start > lastIndex) {
                fragment.appendChild(document.createTextNode(text.slice(lastIndex, entry.start)));
            }

            fragment.appendChild(entry.linker.createLink(entry.match));
            lastIndex = entry.end;
        });

        if (lastIndex < text.length) {
            fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
        }

        textNode.parentNode.replaceChild(fragment, textNode);
    }

    function linkifyNode(rootNode, linkers) {
        if (!rootNode || linkers.length === 0) {
            return;
        }

        if (rootNode.nodeType === Node.TEXT_NODE) {
            if (canProcessTextNode(rootNode)) {
                replaceTextNodeWithLinks(rootNode, linkers);
            }
            return;
        }

        if (rootNode.nodeType !== Node.ELEMENT_NODE) {
            return;
        }

        const walker = document.createTreeWalker(rootNode, NodeFilter.SHOW_TEXT, {
            acceptNode(node) {
                if (!canProcessTextNode(node)) {
                    return NodeFilter.FILTER_REJECT;
                }

                return textHasMatches(node.nodeValue || '', linkers)
                    ? NodeFilter.FILTER_ACCEPT
                    : NodeFilter.FILTER_REJECT;
            }
        });

        const textNodes = [];
        let currentNode;

        while ((currentNode = walker.nextNode())) {
            textNodes.push(currentNode);
        }

        textNodes.forEach((textNode) => replaceTextNodeWithLinks(textNode, linkers));
    }

    function enableLinksForCurrentPage() {
        activeLinkers = getActiveLinkers();

        if (activeLinkers.length === 0) {
            if (linkObserver) {
                linkObserver.disconnect();
                linkObserver = null;
            }
            return;
        }

        if (!document.body) {
            return;
        }

        ensureTicketLinkStyles();
        linkifyNode(document.body, activeLinkers);

        if (linkObserver) {
            return;
        }

        linkObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    linkifyNode(node, activeLinkers);
                });
            });
        });

        linkObserver.observe(document.body, { childList: true, subtree: true });
    }

    function initialize() {
        hotkeys('command+e, ctrl+e', function(event) {
            event.preventDefault();
            transformJenkinsUrl();
        });

        enableLinksForCurrentPage();
        document.addEventListener('turbo:load', enableLinksForCurrentPage);
        document.addEventListener('pjax:end', enableLinksForCurrentPage);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize, { once: true });
    } else {
        initialize();
    }
})();
