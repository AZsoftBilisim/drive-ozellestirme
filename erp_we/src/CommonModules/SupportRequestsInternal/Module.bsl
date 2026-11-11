///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Prepares the form for handling support tickets.
// It is called from the "OnCreateAtServer" form handler with properties.
//
// Parameters:
//  Form - ClientApplicationForm - Form with properties:
//    * Items - FormAllItems - Form items with properties:
//      * AssistanceRequiredGroup           - FormGroup - Section containing UI elements for contacting online support.
//                                                        Mandatory. Not applicable for external user sessions.
//                                                        
//
//      * SupportRequestDetails     - FormDecoration - Support request details.
//                                                           Mandatory. Appears as:
//                                                           1. Details when clicking the buttons
//                                                           "SupportTicket" and "InfoForSupport".
//                                                           2. A formatted string with the URLs
//                                                           "SupportTicket" and "InfoForSupport".
//
//      * SupportTicket                - FormButton - The button that submits a support ticket.
//                                                        Optional.
//
//      * InfoForSupport - FormButton - The button that downloads information to submit to online support.
//                                                        Optional.
//
Procedure OnCreateAtServer(Form) Export
	
	FormItems = Form.Items;
	
	If Users.IsExternalUserSession() Then
		HideNeedHelpSection(FormItems);
		Return;
	EndIf;
	
	DefineFormItemsVisibility(FormItems);
	FillSupportRequestDetails(FormItems);
	
EndProcedure

// Hides the "Need help" section.
//
// Parameters:
//  FormItems - FormAllItems - Form items.
//
Procedure HideNeedHelpSection(FormItems) Export
	
	CommonClientServer.SetFormItemProperty(
		FormItems, "AssistanceRequiredGroup", "Visible", False);
	
EndProcedure

// Make the "Need help" section visible.
// Not applicable to external user sessions.
//
// Parameters:
//  FormItems - FormAllItems - Form items.
//
Procedure ShowNeedHelpSection(FormItems) Export
	
	If Users.IsExternalUserSession() Then
		Return;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		FormItems, "AssistanceRequiredGroup", "Visible", True);
	
EndProcedure

#EndRegion

#Region Private

Procedure DefineFormItemsVisibility(FormItems)
	
	IsSupportTicketAvailable = IsSupportTicketAvailable();
	
	CommonClientServer.SetFormItemProperty(
		FormItems,
		"SupportTicket",
		"Visible",
		IsSupportTicketAvailable);
	
EndProcedure

Procedure FillSupportRequestDetails(FormItems)
	
	SupportRequestDetails = SupportRequestDetails();
	
	If Not IsInteractionViaURLUsed(FormItems) Then
		SupportRequestDetails = String(SupportRequestDetails);
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		FormItems,
		"SupportRequestDetails",
		"Title",
		SupportRequestDetails);
	
EndProcedure

Function IsInteractionViaURLUsed(FormItems)
	
	Result = FormItems.Find("SupportTicket") = Undefined
		And FormItems.Find("InfoForSupport") = Undefined;
	
	Return Result;
	
EndFunction

Function SupportRequestDetails()
	
	IsSupportTicketAvailable = IsSupportTicketAvailable();
	
	If IsSupportTicketAvailable Then
		SupportRequestDetails = StringFunctions.FormattedString(
			NStr("vi = 'Nếu bạn gặp bất kỳ khó khăn nào, vui lòng liên hệ với <a href = %1>dịch vụ hỗ trợ</a>. Nếu cần, hãy cung cấp <a href = %2>thông tin kỹ thuật</a> về vấn đề phát sinh.';
				|ru = 'При возникновении затруднений обратитесь в <a href = %1>службу поддержки</a>. В случае необходимости предоставьте <a href = %2>техническую информацию</a> о возникшей проблеме.';
				|en = 'If you''re facing an issue, contact <a href = %1>online support</a>. If required, provide <a href = %2>technical information</a> about the issue.'; fa = 'If you''re facing an issue, contact <a href = %1>online support</a>. If required, provide <a href = %2>technical information</a> about the issue.';
				|it = 'If you''re facing an issue, contact <a href = %1>online support</a>. If required, provide <a href = %2>technical information</a> about the issue.';
				|pl = 'If you''re facing an issue, contact <a href = %1>online support</a>. If required, provide <a href = %2>technical information</a> about the issue.';
				|tr = 'Sorun yaşarsanız <a href = %1>destek hizmetine</a> başvurun. Gerekmesi durumunda, sorunla ilgili <a href = %2>teknik bilgi</a> sağlayın.'"),
			"SupportTicket",
			"InfoForSupport");
	Else
		SupportRequestDetails = StringFunctions.FormattedString(
			NStr("vi = 'Nếu bạn gặp bất kỳ khó khăn nào, vui lòng liên hệ với dịch vụ hỗ trợ. Nếu cần, hãy cung cấp <a href = %1>thông tin kỹ thuật</a> về vấn đề phát sinh.';
				|ru = 'При возникновении затруднений обратитесь в службу поддержки. В случае необходимости предоставьте <a href = %1>техническую информацию</a> о возникшей проблеме.';
				|en = 'If you''re facing an issue, contact online support. If required, provide <a href = %1>technical information</a> about the issue.'; fa = 'If you''re facing an issue, contact online support. If required, provide <a href = %1>technical information</a> about the issue.';
				|it = 'If you''re facing an issue, contact online support. If required, provide <a href = %1>technical information</a> about the issue.';
				|pl = 'If you''re facing an issue, contact online support. If required, provide <a href = %1>technical information</a> about the issue.';
				|tr = 'Sorun yaşarsanız destek hizmetine başvurun. Gerekmesi durumunda, sorunla ilgili <a href = %1>teknik bilgi</a> sağlayın.'"),
			"InfoForSupport");
	EndIf;
	
	SupportRequestsLocalization.OnDefineSupportRequestDetails(
		SupportRequestDetails,
		IsSupportTicketAvailable);
	
	Return SupportRequestDetails;
	
EndFunction

Function IsSupportTicketAvailable()
	
	Return IsMessagesToTechSupportServiceAvailable() Or IsEmailOperationsAvailable();
	
EndFunction

Function IsMessagesToTechSupportServiceAvailable()
	
	SubsystemExists = Common.SubsystemExists(
		"OnlineUserSupport.MessagesToTechSupportService");
	
	IsOperationsWithExternalResourcesAvailable = Not ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	
	Return SubsystemExists And IsOperationsWithExternalResourcesAvailable;
	
EndFunction

Function IsEmailOperationsAvailable()
	
	Return Common.SubsystemExists("StandardSubsystems.EmailOperations");
	
EndFunction

#EndRegion
