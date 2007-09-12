<%@ page buffer="8kb" session="false" autoFlush="true" pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="javax.naming.*,com.zimbra.cs.zclient.ZAuthResult" %>
<%@ taglib prefix="zm" uri="com.zimbra.zm" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
	// Set to expire far in the past.
	response.setHeader("Expires", "Tue, 24 Jan 2000 17:46:50 GMT");

	// Set standard HTTP/1.1 no-cache headers.
	response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");

	// Set standard HTTP/1.0 no-cache header.
	response.setHeader("Pragma", "no-cache");
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<!--
 launchZCS.jsp
 * ***** BEGIN LICENSE BLOCK *****
 * Version: ZPL 1.2
 *
 * The contents of this file are subject to the Zimbra Public License
 * Version 1.2 ("License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.zimbra.com/license
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 *
 * The Original Code is: Zimbra Collaboration Suite Web Client
 *
 * The Initial Developer of the Original Code is Zimbra, Inc.
 * Portions created by Zimbra are Copyright (C) 2007 Zimbra, Inc.
 * All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK *****
-->
<%!
	private static String protocolMode = null;
	static {
		try {
			Context initCtx = new InitialContext();
			Context envCtx = (Context) initCtx.lookup("java:comp/env");
			protocolMode = (String) envCtx.lookup("protocolMode");
		} catch (NamingException ne) {
			protocolMode = "http";
		}
	}
%>
<%
	String contextPath = request.getContextPath();
	if (contextPath.equals("/")) {
		contextPath = "";
	}

    ZAuthResult authResult = (ZAuthResult) request.getAttribute("authResult");
    String skin = "";
	String requestSkin = request.getParameter("skin");
	if (requestSkin != null) {
		skin = requestSkin;
	} else if (authResult != null) {
	    java.util.List<String> prefSkin = authResult.getPrefs().get("zimbraPrefSkin");
	    if (prefSkin != null && prefSkin.size() > 0) {
	        skin = prefSkin.get(0);
        } else {
            skin = "sand"; // TODO: find better default?
        }
	}
    if (authResult != null) {
        java.util.List<String> localePref = authResult.getPrefs().get("zimbraPrefLocale");
        if (localePref != null && localePref.size() > 0) {
            request.setAttribute("localeId", localePref.get(0));
        }
    }
	String isDev = (String) request.getParameter("dev");
	if (isDev != null) {
		request.setAttribute("mode", "mjsf");
		request.setAttribute("gzip", "false");
		request.setAttribute("fileExtension", "");
		request.setAttribute("debug", "1");
		request.setAttribute("packages", "dev");
	}
	String debug = (String) request.getParameter("debug");
	if (debug == null) {
		debug = (String) request.getAttribute("debug");
	}
	String extraPackages = (String) request.getParameter("packages");
	if (extraPackages == null) {
		extraPackages = (String) request.getAttribute("packages");
	}
	String startApp = (String) request.getParameter("app");
	String noSplashScreen = (String) request.getParameter("nss");
	
	String mode = (String) request.getAttribute("mode");
	Boolean inDevMode = (mode != null) && (mode.equalsIgnoreCase("mjsf"));
	Boolean inSkinDebugMode = (mode != null) && (mode.equalsIgnoreCase("skindebug"));

	String vers = (String) request.getAttribute("version");
	if (vers == null) vers = "";

	String prodMode = String.valueOf(request.getAttribute("prodMode"));
	if (prodMode == null) prodMode = "";

	String ext = (String) request.getAttribute("fileExtension");
	if (ext == null || inDevMode) ext = "";
	
	String offlineMode = (String) request.getParameter("offline");
	if (offlineMode == null) {
		offlineMode = application.getInitParameter("offlineMode");
	}
	
    String localeQs = "";
    String localeId = (String) request.getAttribute("localeId");
    if (localeId != null) {
        int index = localeId.indexOf("_");
        if (index == -1) {
            localeQs = "&language=" + localeId;
        } else {
            localeQs = "&language=" + localeId.substring(0, index) +
                       "&country=" + localeId.substring(localeId.length() - 2);
        }
    }
%>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
<fmt:setLocale value='${pageContext.request.locale}' scope='request' />
<title><fmt:setBundle basename="/messages/ZmMsg"/><fmt:message key="zimbraTitle"/></title>
<link href="<%=contextPath %>/css/images,common,dwt,msgview,login,zm,spellcheck,wiki,skin?v=<%= vers %><%= inSkinDebugMode || inDevMode ? "&debug=1" : "" %>&skin=<%= skin %>" rel="stylesheet" type="text/css" />
<link href="<%=contextPath %>/favicon.ico" rel="SHORTCUT ICON" />
</head>
<body>
<noscript><fmt:setBundle basename="/messages/ZmMsg"/>
<fmt:message key="errorJavaScriptRequired"><fmt:param><c:url context="/zimbra" value='/h/'></c:url></fmt:param></fmt:message>
</noscript>
<%!
	public class Wrapper extends HttpServletRequestWrapper {
		public Wrapper(HttpServletRequest req, String skin) {
			super(req);
			this.skin = skin;
		}
		String skin;
    	public String getServletPath() { return "/html"; }
	    public String getPathInfo() { return "/skin.html"; }
	    public String getRequestURI() { return getServletPath() + getPathInfo(); }
	    public String getParameter(String name) {
	    	if (name.equals("skin")) return this.skin;
			if (name.equals("client")) return "advanced";
			return super.getParameter(name);
	    }
	}
%>
<%
	// NOTE: This inserts raw HTML files from the user's skin
	//       into the JSP output. It's done *this* way so that
	//       the SkinResources servlet sees the request URI as
	//       "/html/skin.html" and not as "/public/launch...".
	out.flush();
	RequestDispatcher dispatcher = request.getRequestDispatcher("/html/");
	HttpServletRequest wrappedReq = new Wrapper(request, skin);
	dispatcher.include(wrappedReq, response);
%>
<script>
	function populateText(){
		if(arguments.length == 0 ) return;
		var node, index = 0, length = arguments.length;
		while(index < length){
			node = document.getElementById(arguments[index]);
			if(node) node.appendChild(document.createTextNode(arguments[index+1]));
			index += 2;
		}
	}
<fmt:message key="splashScreenAppName" var="splashScreenAppName"/>
<fmt:message key="splashScreenLoading" var="splashScreenLoading"/>
<fmt:message key="splashScreenCopyright" var="splashScreenCopyright"/>
	populateText(
		"ZLoginAppName",			"${zm:jsEncode(splashScreenAppName)}",
        "ZLoginLoadingMsg",			"${zm:jsEncode(splashScreenLoading)}",
        "ZLoginLicenseContainer",	"${zm:jsEncode(splashScreenCopyright)}"
	); 
    appContextPath = "<%=contextPath %>";
	appCurrentSkin = "<%=skin %>";
	appExtension   = "<%=ext%>";
	appDevMode     = <%=inDevMode%>;
	
</script>
<% request.setAttribute("res", "I18nMsg,AjxMsg,ZMsg,ZmMsg,AjxKeys,ZmKeys"); %>
<jsp:include page="Resources.jsp" />
<jsp:include page="Boot.jsp"/>
<%
	String allPackages = "Startup1_1,Startup1_2";
    if (extraPackages != null) {
    	if (extraPackages.equals("dev")) {
    		extraPackages = "Startup2,CalendarCore,Calendar,CalendarAppt,ContactsCore,Contacts,IM,MailCore,Mail,Mixed,NotebookCore,Notebook,BriefcaseCore,Briefcase,PreferencesCore,Preferences,TasksCore,Tasks,Voicemail,Assistant,Browse,Extras,Share,Zimlet,Portal";
    	}
    	allPackages += "," + extraPackages;
    }

    String pprefix = inDevMode ? "public/jsp" : "js";
    String psuffix = inDevMode ? ".jsp" : "_all.js";

    String[] pnames = allPackages.split(",");
    for (String pname : pnames) {
        String pageurl = "/" + pprefix + "/" + pname + psuffix;
        if (inDevMode) { %>
            <jsp:include>
                <jsp:attribute name='page'><%=pageurl%></jsp:attribute>
            </jsp:include>
        <% } else { %>
            <script src="<%=contextPath%><%=pageurl%><%=ext%>?v=<%=vers%>"></script> 
        <% } %>
    <% }
%>

<script type="text/javascript" src="<%=contextPath%>/js/skin.js?v=<%=vers %>&skin=<%=skin%><%= inSkinDebugMode || inDevMode ? "&debug=1" : "" %><%=localeQs%>"></script>

<script>

	AjxEnv.DEFAULT_LOCALE = "<%=request.getLocale()%>";

	<zm:getDomainInfo var="domainInfo" by="virtualHostname" value="${zm:getServerName(pageContext)}"/> 
		var settings = {
			"dummy":1<c:forEach var="pref" items="${requestScope.authResult.prefs}">,
			"${pref.key}":"${zm:jsEncode(pref.value[0])}"</c:forEach>
			<c:forEach var="attr" items="${requestScope.authResult.attrs}">,
			"${attr.key}":"${zm:jsEncode(attr.value[0])}"</c:forEach>
			<c:if test="${not empty domainInfo}"> 
			<c:forEach var="info" items="${domainInfo.attrs}">,
			"${info.key}":"${zm:jsEncode(info.value)}"</c:forEach> 
			</c:if>
		};

	var cacheKillerVersion = "<%=vers%>";
	function launch() {
		// quit if this function has already been called
		if (arguments.callee.done) {return;}

		// flag this function so we don't do the same thing twice
		arguments.callee.done = true;

		// kill the timer
		if (_timer) {
			clearInterval(_timer);
			_timer = null;
		}

		var prodMode = <%=prodMode%>;
		var debugLevel = "<%= (debug != null) ? debug : "" %>";
		if (!prodMode || debugLevel) {
			AjxDispatcher.require("Debug");
			DBG = new AjxDebug(AjxDebug.NONE, null, false);
			AjxWindowOpener.HELPER_URL = "<%=contextPath%>/public/frameOpenerHelper.jsp";
			// figure out the debug level
			if (debugLevel == 't') {
				DBG.showTiming(true);
			} else {
				DBG.setDebugLevel(debugLevel);
			}
		}

		AjxHistoryMgr.BLANK_FILE = "<%=contextPath%>/public/blankHistory.html";
		var app = "<%= (startApp != null) ? startApp : "" %>";
		var noSplashScreen = "<%= (noSplashScreen != null) ? noSplashScreen : "" %>";
		var offlineMode = "<%= (offlineMode != null) ? offlineMode : "" %>";
		var isDev = "<%= (isDev != null) ? isDev : "" %>";
		var protocolMode = "<%=protocolMode%>";

        <%--
        <zm:getInfoJSON var="getInfoJSON" authtoken="${requestScope.authResult.authToken}"/>
        var getInfoResponse = ${getInfoJSON};
        --%>

        var getInfoResponse = null;
		var searchResponse = null;
		if (/\bgir\b/.test(location.search)) {
			getInfoResponse = {"Body":{"GetInfoResponse":{"zimlets":{"zimlet":[{"zimlet":[{"contentObject":[{"contextMenu":[{"menuItem":[{"label":"Day","icon":"DayView","id":"DAYVIEW"},{"label":"New Appointment","icon":"NewAppointment","id":"NEWAPPT"},{},{"label":"Email Messages","icon":"SearchMail","id":"SEARCHMAIL"}]}],"type":"date"}],"include":[{"_content":"date.js"}],"description":"Date","handlerObject":[{"_content":"Com_Zimbra_Date"}],"name":"com_zimbra_date","version":"1.0"}],"zimletContext":[{"baseUrl":"/service/zimlet/com_zimbra_date/","priority":0}]},{"zimlet":[{"contentObject":[{"contextMenu":[{"menuItem":[{"label":"Search","icon":"Search","id":"SEARCH"},{"label":"Advanced Search","icon":"NewContact","id":"SEARCHBUILDER"},{"label":"New Email","icon":"NewMessage","id":"NEWEMAIL"},{"label":"Edit Contact","icon":"Edit","id":"NEWCONTACT"},{"label":"New Filter","icon":"Plus","id":"NEWFILTER"},{"label":"Go to URL","icon":"URL","id":"GOTOURL"}]}],"type":"email","matchOn":[{"regex":[{"_content":"\\b(mailto:[ ]*)?([0-9a-zA-Z]+[-._+&])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}([\\w/_\\.]*(\\?\\S+)?)\\b","attrs":"g"}]}]}],"include":[{"_content":"email.js"}],"description":"Email","handlerObject":[{"_content":"Com_Zimbra_Email"}],"name":"com_zimbra_email","version":"1.0"}],"zimletContext":[{"baseUrl":"/service/zimlet/com_zimbra_email/","priority":1}]},{"zimletConfig":[{"name":"com_zimbra_html","global":[{}],"version":"1.0"}],"zimlet":[{"portlet":[{"portletProperties":[{"property":[{"value":"about:blank","type":"string","label":"URL","name":"url"},{"type":"number","label":"Refresh (ms)","name":"refresh"}]}]}],"include":[{"_content":"html.js"}],"description":"HTML","handlerObject":[{"_content":"Com_Zimbra_Html"}],"name":"com_zimbra_html","version":"1.0"}],"zimletContext":[{"baseUrl":"/service/zimlet/com_zimbra_html/","priority":2}]},{"zimletConfig":[{"name":"com_zimbra_phone","global":[{"property":[{"_content":"companyPhone","name":"defaultContactField"}]}],"version":"1.0"}],"zimlet":[{"contentObject":[{"contextMenu":[{"menuItem":[{"label":"Search","icon":"Search","id":"SEARCH"},{"label":"Add to Contacts","icon":"NewContact","id":"ADDCONTACT"},{"label":"Skype Call","icon":"Telephone","id":"CALL"}]}],"type":"phone","matchOn":[{"regex":[{"_content":"(\\W|^)((?:(?:\\+|00)\\d+[-.\\s]?)?(?:(?:\\(\\d{2,3}\\)[-.\\s]?|\\d{2,3}[-.\\s]?))?\\d{3}[-.\\s]?\\d{3,4})(\\W|$)","paren":"2"}]}]}],"include":[{"_content":"phone.js"},{"_content":"templates/Phone.js"}],"description":"Phone Number","serverExtension":[{"extensionClass":"com.zimbra.cs.zimlet.handler.NANPHandler","hasKeyword":"phone"}],"handlerObject":[{"_content":"Com_Zimbra_Phone"}],"name":"com_zimbra_phone","version":"1.2"}],"zimletContext":[{"baseUrl":"/service/zimlet/com_zimbra_phone/","priority":3}]},{"zimletConfig":[{"name":"com_zimbra_search","global":[{"property":[{"_content":"pub-8230960882754720","name":"google-account"},{"_content":"\n <!-- Search Google -->\n <form method=\"get\" action=\"http://www.google.com/custom\" target=\"_blank\">\n <input type=\"text\" name=\"q\" size=\"31\" value=\"${prop.query}\"></input>\n <input type=\"hidden\" name=\"sa\" value=\"Google Search\"></input>\n <input type=\"hidden\" name=\"client\" value=\"${prop.acct}\"></input>\n <input type=\"hidden\" name=\"channel\" value=\"7833156184\"></input>\n <input type=\"hidden\" name=\"forid\" value=\"1\"></input>\n <input type=\"hidden\" name=\"ie\" value=\"ISO-8859-1\"></input>\n <input type=\"hidden\" name=\"oe\" value=\"ISO-8859-1\"></input>\n <input type=\"hidden\" name=\"cof\" value=\"GALT:008000;GL:1;DIV:336699;VLC:663399;AH:center;BGC:FFFFFF;LBGC:336699;ALC:0000FF;LC:0000FF;T:000000;GFNT:0000FF;GIMP:0000FF;FORID:1\"></input>\n <input type=\"hidden\" name=\"hl\" value=\"en\"></input>\n </form>\n <!-- Search Google -->\n ","name":"google-search-code"},{"_content":"\n <form action=\"http://en.wikipedia.org/wiki/Special:Search\" target=\"_blank\">\n <input name=\"search\" value=\"${prop.query}\" type=\"text\">\n <input name=\"go\" value=\"Go\" type=\"hidden\">\n </form>\n ","name":"wikipedia-search-code"}]}],"version":"1.0"}],"zimlet":[{"include":[{"_content":"search.js"},{"_content":"google-search.js"}],"description":"Search the Web using the Google(TM) search engine","resource":[{"_content":"google.gif"}],"handlerObject":[{"_content":"Com_Zimbra_Search"}],"includeCSS":[{"_content":"search.css"}],"name":"com_zimbra_search","version":"1.0"}],"zimletContext":[{"baseUrl":"/service/zimlet/com_zimbra_search/","priority":4}]},{"zimletConfig":[{"name":"com_zimbra_url","global":[{"property":[{"_content":"((telnet:)|((https?|ftp|gopher|news|file):\\/\\/)|(www.[\\w\\.\\_\\-]+))[^\\s\\(\\)\\<\\>\\[\\]\\{\\}\\'\\\"]*","name":"ZIMLET_CONFIG_REGEX_VALUE"},{"_content":"true","name":"stripUrls"},{"_content":"true","name":"disablePreview"}]}],"version":"1.0"}],"zimlet":[{"contentObject":[{"type":"url","matchOn":[{"regex":[{"_content":"((telnet:)|((https?|ftp|gopher|news|file):\\/\\/)|(www\\.[\\w\\.\\_\\-]+))[^\\s\\xA0\\(\\)\\<\\>\\[\\]\\{\\}\\'\\\"]*","attrs":"ig"}]}]}],"include":[{"_content":"url.js"}],"description":"URL","serverExtension":[{"extensionClass":"com.zimbra.cs.zimlet.handler.RegexHandler","hasKeyword":"url"}],"resource":[{"_content":"blank_pixel.gif"}],"handlerObject":[{"_content":"Com_Zimbra_Url"}],"name":"com_zimbra_url","version":"1.3"}],"zimletContext":[{"baseUrl":"/service/zimlet/com_zimbra_url/","priority":5}]}]},"props":{},"dataSources":{},"lifetime":170071094,"prefs":{"_attrs":{"zimbraPrefGalAutoCompleteEnabled":"FALSE","zimbraPrefMailPollingInterval":"3600","zimbraPrefGroupMailBy":"conversation","zimbraPrefCalendarDayHourStart":"8","zimbraPrefTrashLifetime":"0","zimbraPrefMessageViewHtmlPreferred":"TRUE","zimbraPrefReadingPaneEnabled":"TRUE","zimbraPrefInboxUnreadLifetime":"0","zimbraPrefCalendarUseQuickAdd":"TRUE","zimbraPrefIMNotifyStatus":"TRUE","zimbraPrefJunkLifetime":"0","zimbraPrefShowFragments":"TRUE","zimbraPrefHtmlEditorDefaultFontSize":"12pt","zimbraPrefForwardIncludeOriginalText":"includeBody","zimbraPrefUseKeyboardShortcuts":"TRUE","zimbraPrefIMLogChatsEnabled":"TRUE","zimbraPrefCalendarAlwaysShowMiniCal":"TRUE","zimbraPrefShowSelectionCheckbox":"FALSE","zimbraPrefDisplayExternalImages":"FALSE","zimbraPrefMailItemsPerPage":"10","zimbraPrefForwardReplyInOriginalFormat":"FALSE","zimbraPrefContactsPerPage":"25","zimbraPrefMailSignatureStyle":"outlook","zimbraPrefComposeInNewWindow":"FALSE","zimbraPrefSaveToSent":"TRUE","zimbraPrefAutoAddAddressEnabled":"TRUE","zimbraPrefForwardReplyPrefixChar":">","zimbraPrefCalendarDayHourEnd":"18","zimbraPrefCalendarNotifyDelegatedChanges":"FALSE","zimbraPrefReplyIncludeOriginalText":"includeBody","zimbraPrefTimeZoneId":"(GMT-08.00) Pacific Time (US & Canada)","zimbraPrefMailInitialSearch":"in:inbox","zimbraPrefUseRfc2231":"FALSE","zimbraPrefUseTimeZoneListInCalendar":"FALSE","zimbraPrefCalendarApptReminderWarningTime":"5","zimbraPrefLocale":"en_US","zimbraPrefImapSearchFoldersEnabled":"TRUE","zimbraPrefSentLifetime":"0","zimbraPrefMailDefaultCharset":"UTF-8","zimbraPrefIncludeSpamInSearch":"FALSE","zimbraPrefClientType":"advanced","zimbraPrefDeleteInviteOnReply":"TRUE","zimbraPrefSkin":"sand","zimbraPrefIMInstantNotify":"TRUE","zimbraPrefContactsInitialView":"list","zimbraPrefWarnOnExit":"TRUE","zimbraPrefVoiceItemsPerPage":"25","zimbraPrefHtmlEditorDefaultFontFamily":"Times New Roman","zimbraPrefHtmlEditorDefaultFontColor":"#000000","zimbraPrefSentMailFolder":"sent","zimbraPrefIMNotifyPresence":"TRUE","zimbraPrefIMFlashIcon":"TRUE","zimbraPrefIncludeTrashInSearch":"FALSE","zimbraPrefOpenMailInNewWindow":"FALSE","zimbraPrefCalendarFirstDayOfWeek":"0","zimbraPrefComposeFormat":"text","zimbraPrefIMAutoLogin":"FALSE","zimbraPrefInboxReadLifetime":"0","zimbraPrefShowSearchString":"TRUE","zimbraPrefCalendarInitialView":"workWeek","zimbraPrefDedupeMessagesSentToSelf":"dedupeNone"}},"identities":{"identity":[{"_attrs":{"zimbraPrefSentMailFolder":"sent","zimbraPrefForwardIncludeOriginalText":"includeBody","zimbraPrefMailSignatureStyle":"outlook","zimbraPrefFromAddress":"user1@laika2.zimbra.com","zimbraPrefSaveToSent":"TRUE","zimbraPrefIdentityName":"DEFAULT","zimbraPrefFromDisplay":"Demo User One","zimbraPrefForwardReplyFormat":"text","zimbraPrefForwardReplyPrefixChar":">","zimbraPrefReplyIncludeOriginalText":"includeBody","zimbraPrefIdentityId":"5c11b358-bb7a-48c1-ba83-f4750ff7916c"},"name":"DEFAULT","id":"5c11b358-bb7a-48c1-ba83-f4750ff7916c"}]},"id":"5c11b358-bb7a-48c1-ba83-f4750ff7916c","version":"5.0 cdamon 20070830-1959","attrs":{"_attrs":{"zimbraFeatureVoiceUpsellEnabled":"FALSE","zimbraContactMaxNumEntries":"0","zimbraFeatureCalendarUpsellEnabled":"FALSE","zimbraFeatureOptionsEnabled":"TRUE","zimbraFeatureMailPollingIntervalPreferenceEnabled":"TRUE","zimbraFeatureViewInHtmlEnabled":"FALSE","zimbraPortalName":"example","zimbraFeatureTasksEnabled":"TRUE","zimbraPrefReadingPaneEnabled":"TRUE","zimbraFeatureGalAutoCompleteEnabled":"TRUE","zimbraFeatureFlaggingEnabled":"TRUE","zimbraFeatureBriefcasesEnabled":"FALSE","zimbraFeatureGalEnabled":"TRUE","zimbraFeatureSkinChangeEnabled":"TRUE","zimbraMailMinPollingInterval":"2m","zimbraFeatureSavedSearchesEnabled":"TRUE","zimbraAllowAnyFromAddress":"FALSE","zimbraIdentityMaxNumEntries":"20","zimbraPasswordMinLowerCaseChars":"0","uid":"user1","zimbraMailIdleSessionTimeout":"0","zimbraFeatureOutOfOfficeReplyEnabled":"TRUE","zimbraSignatureMaxNumEntries":"20","zimbraFeatureAdvancedSearchEnabled":"TRUE","zimbraLocale":"en_US","zimbraFeaturePortalEnabled":"FALSE","zimbraFeatureIMEnabled":"FALSE","zimbraFeatureVoiceEnabled":"FALSE","zimbraFeatureZimbraAssistantEnabled":"TRUE","zimbraPasswordMinPunctuationChars":"0","zimbraZimletAvailableZimlets":["com_zimbra_date","com_zimbra_email","com_zimbra_html","com_zimbra_phone","com_zimbra_search","com_zimbra_url"],"displayName":"Demo User One","zimbraPasswordMinUpperCaseChars":"0","zimbraDataSourceMinPollingInterval":"1m","zimbraFeatureSharingEnabled":"TRUE","zimbraFeatureSignaturesEnabled":"TRUE","zimbraMailSignatureMaxLength":"1024","zimbraFeatureConversationsEnabled":"TRUE","zimbraFeatureMailEnabled":"TRUE","zimbraFeatureGroupCalendarEnabled":"TRUE","zimbraPasswordMaxLength":"64","zimbraFeatureNewMailNotificationEnabled":"TRUE","zimbraFeatureContactsUpsellEnabled":"FALSE","zimbraId":"5c11b358-bb7a-48c1-ba83-f4750ff7916c","zimbraFeatureHtmlComposeEnabled":"TRUE","zimbraFeatureContactsEnabled":"TRUE","zimbraFeatureNotebookEnabled":"TRUE","zimbraFeatureMailForwardingEnabled":"TRUE","zimbraSignatureMinNumEntries":"1","zimbraFeatureCalendarEnabled":"TRUE","zimbraAttachmentsBlocked":"FALSE","zimbraFeaturePop3DataSourceEnabled":"TRUE","zimbraFeatureShortcutAliasesEnabled":"TRUE","zimbraPasswordMinLength":"6","zimbraDataSourceMaxNumEntries":"20","zimbraFeatureInstantNotify":"TRUE","zimbraFeatureTaggingEnabled":"TRUE","zimbraFeatureMailUpsellEnabled":"FALSE","zimbraFeatureIdentitiesEnabled":"TRUE","zimbraFeatureFiltersEnabled":"TRUE","cn":"Demo User One","zimbraPasswordMinNumericChars":"0","zimbraMailQuota":"62914560","zimbraFeatureInitialSearchPreferenceEnabled":"TRUE","zimbraFeatureChangePasswordEnabled":"TRUE"}},"soapURL":"http://laika2.zimbra.com:7070/service/soap/","childAccounts":{},"accessed":1189213448000,"prevSession":1189213448000,"recent":0,"signatures":{},"name":"user1@laika2.zimbra.com","used":10836774,"_jsns":"urn:zimbraAccount"}},"Header":{"context":{"sessionId":[{"_content":"13","id":"13"}],"change":{"token":1199},"refresh":{"mbx":{"s":10836774},"tags":{},"folder":[{"search":[{"types":"conversation","query":"is:flagged","sortBy":"dateDesc","l":"1","name":"Flagged","id":"284","rev":29},{"types":"conversation","query":"has:attachment","sortBy":"dateDesc","l":"1","name":"Has Attachment","id":"285","rev":30},{"types":"conversation","query":"larger:100kb","sortBy":"dateDesc","l":"1","name":"Large","id":"286","rev":31},{"types":"conversation","query":"after:-7d","sortBy":"dateDesc","l":"1","name":"Recent","id":"287","rev":32},{"types":"conversation","query":"is:unread","sortBy":"dateDesc","l":"1","name":"Unread Messages","id":"283","rev":28}],"n":0,"l":"11","folder":[{"view":"wiki","rest":"http://laika2.zimbra.com:7070/home/user1/_Engineering","n":1,"l":"1","name":"_Engineering","s":17403,"id":"559","rev":260},{"view":"wiki","rest":"http://laika2.zimbra.com:7070/home/user1/_ProductPlanning","n":1,"l":"1","folder":[{"view":"wiki","rest":"http://laika2.zimbra.com:7070/home/user1/_ProductPlanning/PrototypesAndMockUps","n":1,"l":"561","name":"PrototypesAndMockUps","s":4512,"id":"562","rev":263}],"name":"_ProductPlanning","s":678,"id":"561","rev":262},{"view":"document","n":7,"l":"1","name":"Briefcase","s":3044964,"id":"16","rev":1},{"view":"appointment","f":"#","rest":"http://laika2.zimbra.com:7070/home/user1/Calendar","n":15,"l":"1","name":"Calendar","s":67105,"id":"10","rev":1},{"view":"message","n":0,"l":"1","name":"Chats","s":0,"id":"14","rev":1},{"view":"contact","rest":"http://laika2.zimbra.com:7070/home/user1/Contacts","n":26,"l":"1","name":"Contacts","s":0,"id":"7","rev":1},{"view":"message","n":0,"l":"1","name":"Drafts","s":0,"id":"6","rev":1},{"view":"contact","rest":"http://laika2.zimbra.com:7070/home/user1/Emailed%20Contacts","n":1,"l":"1","name":"Emailed Contacts","s":0,"id":"13","rev":1},{"view":"message","u":179,"f":"u","n":215,"l":"1","name":"Inbox","s":6964412,"id":"2","rev":1},{"view":"message","u":1,"f":"u","n":1,"l":"1","name":"Junk","s":6449,"id":"4","rev":1},{"view":"wiki","rest":"http://laika2.zimbra.com:7070/home/user1/Notebook","n":1,"l":"1","name":"Notebook","s":98,"id":"12","rev":1},{"view":"message","n":2,"l":"1","name":"Sent","s":13205,"id":"5","rev":1},{"view":"task","f":"#","rest":"http://laika2.zimbra.com:7070/home/user1/Tasks","n":0,"l":"1","name":"Tasks","s":0,"id":"15","rev":1},{"view":"message","u":1,"f":"u","n":5,"l":"1","name":"test","s":25791,"id":"580","rev":402},{"view":"message","n":1,"l":"1","name":"test1","s":683513,"id":"620","rev":1104},{"n":3,"l":"1","name":"Trash","s":8644,"id":"3","rev":1}],"name":"USER_ROOT","s":0,"id":"1","rev":1}]},"_jsns":"urn:zimbra"}},"_jsns":"urn:zimbraSoap"};
			searchResponse = {"Body":{"SearchResponse":{"more":true,"c":[{"d":1189459297000,"m":[{"id":"553"}],"sf":"1189459297000","score":1.0,"su":"Welcome to the Zimbra Collaboration Suite source!","f":"u","n":1,"fr":"Greetings. This is a sample message in the source code. You can drop other sample messages in this directory (ZimbraServer\\data\\TestMailRaw) - during ...","id":"-553","e":[{"d":"Zimbra","a":"zimbra@example.com","t":"f","p":"Zimbra Team"}]},{"d":1189459297000,"m":[{"id":"556"}],"sf":"1189459297000","score":1.0,"su":"Rich text (TNEF) test","f":"au","n":1,"fr":"> This is a rich text message with attachments. > You better support this industry-standard file format or else. >","id":"-556","e":[{"d":"Phil","a":"pillb@foobarbaz.com","t":"f","p":"Phil Bates"}]},{"d":1189459294000,"m":[{"id":"540"}],"sf":"1189459294000","score":1.0,"su":"Goodmail test","f":"u","n":1,"fr":"Tastes great!","id":"-540","e":[{"d":"goodmailbot42","a":"goodmailbot42@aol.com","t":"f"}]},{"d":1189459293000,"m":[{"id":"537"}],"sf":"1189459293000","score":1.0,"su":"envelope testing","f":"u","n":1,"fr":"testing","id":"-537","e":[{"d":"lie1","a":"lie1@example.com","t":"f"}]},{"d":1189459292000,"m":[{"id":"530"}],"sf":"1189459292000","score":1.0,"su":"Updated: Web Services SDK","f":"uv","n":1,"fr":"When: Monday, June 06, 2005 2:00 PM-4:00 PM (GMT-08:00) Pacific Time (US & Canada); Tijuana. Where: board room *~*~*~*~*~*~*~*~*~*","id":"-530","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459292000,"m":[{"id":"532"}],"sf":"1189459292000","score":1.0,"su":"","f":"au","n":1,"fr":"","id":"-532","e":[{"d":"user01","a":"user01@testdomain.com","t":"f"}]},{"d":1189459291000,"m":[{"id":"526"}],"sf":"1189459291000","score":1.0,"su":"Apple WWDC in San Francisco","f":"uv","n":1,"fr":"When: Monday, June 06, 2005 12:00 AM to Saturday, June 11, 2005 12:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-526","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459291000,"m":[{"id":"528"}],"sf":"1189459291000","score":1.0,"su":"Lab trial update","f":"uv","n":1,"fr":"When: Tuesday, June 07, 2005 9:00 AM-9:30 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-528","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459290000,"m":[{"id":"520"}],"sf":"1189459290000","score":1.0,"su":"Kitchen remodel","f":"uv","n":1,"fr":"When: Thursday, June 09, 2005 12:00 AM to Friday, June 17, 2005 12:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-520","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459290000,"m":[{"id":"522"}],"sf":"1189459290000","score":1.0,"su":"One day all day test","f":"uv","n":1,"fr":"When: Wednesday, June 08, 2005 12:00 AM to Thursday, June 09, 2005 12:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-522","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459290000,"m":[{"id":"524"}],"sf":"1189459290000","score":1.0,"su":"Another all day appt test","f":"uv","n":1,"fr":"When: Friday, June 03, 2005 12:00 AM to Wednesday, June 08, 2005 12:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-524","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459289000,"m":[{"id":"514"}],"sf":"1189459289000","score":1.0,"su":"Recurring Meeting Test","f":"uv","n":1,"fr":"Type:Single Meeting Organizer:Roland Schemers Start Time:Friday, March 11, 2005 10:30 AM End Time:Friday, March 11, 2005 11:30 AM Time ...","id":"-514","e":[{"d":"Roland","a":"smith@example.zimbra.com","t":"f","p":"Roland Smith"}]},{"d":1189459289000,"m":[{"id":"516"}],"sf":"1189459289000","score":1.0,"su":"Inbox - San Jose","f":"uv","n":1,"fr":"When: Wednesday, June 01, 2005 12:00 AM to Friday, June 03, 2005 12:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-516","e":[{"d":"events","a":"events@dev.example.zimbra.com","t":"f"}]},{"d":1189459289000,"m":[{"id":"518"}],"sf":"1189459289000","score":1.0,"su":"Calendar milestone","f":"uv","n":1,"fr":"When: Wednesday, June 08, 2005 12:00 AM to Saturday, June 11, 2005 12:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-518","e":[{"d":"User1","a":"user1@example.zimbra.com","t":"f","p":"User1"}]},{"d":1189459288000,"m":[{"id":"508"}],"sf":"1189459288000","score":1.0,"su":"Conf call","f":"uv","n":1,"fr":"When: Friday, June 10, 2005 9:00 AM-11:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. Where: office *~*~*~*~*~*~*~*~*~*","id":"-508","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459288000,"m":[{"id":"510"}],"sf":"1189459288000","score":1.0,"su":"Calendar Discussion","f":"uv","n":1,"fr":"When: Thursday, June 09, 2005 10:00 AM-12:00 PM (GMT-08:00) Pacific Time (US & Canada); Tijuana. Where: Stanford *~*~*~*~*~*~*~*~*~*","id":"-510","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459288000,"m":[{"id":"512"}],"sf":"1189459288000","score":1.0,"su":"System Upgrade","f":"uv","n":1,"fr":"When: Tuesday, June 07, 2005 10:00 PM to Wednesday, June 08, 2005 1:00 AM (GMT-08:00) Pacific Time (US & Canada); Tijuana. Where: Office ...","id":"-512","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459287000,"m":[{"id":"504"}],"sf":"1189459287000","score":1.0,"su":"Test cross day","f":"uv","n":1,"fr":"When: Thursday, May 19, 2005 5:00 PM to Friday, May 20, 2005 3:00 PM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-504","e":[{"d":"Roland","a":"schemers@example.zimbra.com","t":"f","p":"Roland Schemers"}]},{"d":1189459287000,"m":[{"id":"506"}],"sf":"1189459287000","score":1.0,"su":"Admin Meeting","f":"uv","n":1,"fr":"When: Monday, June 06, 2005 3:30 PM-5:00 PM (GMT-08:00) Pacific Time (US & Canada); Tijuana. *~*~*~*~*~*~*~*~*~*","id":"-506","e":[{"d":"User","a":"user1@example.zimbra.com","t":"f","p":"User One"}]},{"d":1189459262000,"m":[{"id":"378"}],"sf":"1189459262000","score":1.0,"su":"P4 #16130 ( bug: 4570 static linking for bdb dependencies )","f":"u","n":1,"fr":"Change 16130 by build@BUILD_FC3 on 2005/11/09 12:18:27 http://bugzilla.liquidsys.com/show_bug.cgi?id=4570 bug: 4570 bug 4560 bug #4550 bugzilla #4540 ...","id":"-378","e":[{"d":"build","a":"build@acme.com","t":"f","p":"build"}]},{"d":1189459261000,"m":[{"id":"375"}],"sf":"1189459261000","score":1.0,"su":"Meeting Follow Up","f":"u","n":1,"fr":"Chris- We had a great meeting with MySQL at LinuxWorld. You can read more about their new offer at http://www.mysql.com/products/database/cluster/. ...","id":"-375","e":[{"d":"Job","a":"job@example.com","t":"f","p":"Job"}]},{"d":1127421335000,"m":[{"id":"364"},{"id":"290"}],"sf":"1127421335000","score":1.0,"su":"Re: Future XMLBeans feature work?","f":"u","n":4,"fr":"I completely agree, start-from-java can be very complex. I'd be interested if you can expand any of the lessons you've seen in betwixt in this area. ...","id":"346","e":[{"d":"Ted","a":"twleung@sauria.com","t":"f","p":"Ted Leung"},{"d":"Roland","a":"smith@stanford.edu","t":"f","p":"Roland Smith"},{"d":"David","a":"david.bau@bea.com","t":"f","p":"David Bau"}]},{"d":1127085406000,"m":[{"id":"466"},{"id":"454"}],"sf":"1127085406000","score":1.0,"su":"Re: Future XMLBeans feature work?","f":"u","n":3,"fr":"From: \"Ted Leung\" <twleung@sauria.com> ... Cool. Here's the text as it stands right now, just pasted from the wiki: = XmlBeansFeaturePlan = This is a ...","id":"455","e":[{"d":"David","a":"david.bau@bea.com","t":"f","p":"David Bau"}]},{"d":1118783664000,"m":[{"id":"534"}],"sf":"1118783664000","score":1.0,"su":"test dates","f":"u","n":1,"fr":"2005-06-06 2005-12-25 12-25-2005 06-06-05 2005/06/06 2004/12/25 12/25/2005 6/6/68 06/06/1968 03/26/98 03/27/03 June 6, 2004 25th December 6th, June ...","id":"-534","e":[{"d":"user1","a":"user1@example.zimbra.com","t":"f"}]},{"d":1110504819000,"m":[{"id":"542"}],"sf":"1110504819000","score":1.0,"su":"Customer Conf Call","f":"uv","n":1,"fr":"testing","id":"-542","e":[{"d":"Roland","a":"smith@example.zimbra.com","t":"f","p":"Roland Smith"}]}],"sortBy":"dateDesc","offset":0,"_jsns":"urn:zimbraMail"}},"Header":{"context":{"sessionId":[{"_content":"12","id":"12"}],"change":{"token":399},"_jsns":"urn:zimbra"}},"_jsns":"urn:zimbraSoap"};
		}
		
		var params = {app:app, offlineMode:offlineMode, devMode:isDev, settings:settings,
					  protocolMode:protocolMode, noSplashScreen:noSplashScreen,
					  getInfoResponse:getInfoResponse, searchResponse:searchResponse};
		ZmZimbraMail.run(params);
	}

    //	START DOMContentLoaded
    // Mozilla and Opera 9 expose the event we could use
    if (document.addEventListener) {
        document.addEventListener("DOMContentLoaded", launch, null);

        //	mainly for Opera 8.5, won't be fired if DOMContentLoaded fired already.
        document.addEventListener("load", launch, null);
    }

    // 	for Internet Explorer. readyState will not be achieved on init call
    if (AjxEnv.isIE && AjxEnv.isWindows) {
        document.attachEvent("onreadystatechange", function(e) {
            if (document.readyState == "complete") {
                launch();
            }
        });
    }

    if (/(WebKit|khtml)/i.test(navigator.userAgent)) { // sniff
        var _timer = setInterval(function() {
            if (/loaded|complete/.test(document.readyState)) {
                launch();
                // call the onload handler
            }
        }, 10);
    }
    //	END DOMContentLoaded

    AjxCore.addOnloadListener(launch);
    AjxCore.addOnunloadListener(ZmZimbraMail.unload);
</script>
</body>
</html>