///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DistributionRef = Parameters.Ref;
	MailoutStatus = ReportMailing.GetReportDistributionState(DistributionRef);
	
	If MailoutStatus.WithErrors Then 
		Items.HeadingDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã gửi báo cáo (%1) hàng loạt không phải cho tất cả người nhận. Thử gửi lại cho người nhận sau:';
				|ru = 'Рассылка отчетов (%1) была отправлена не всем получателям. Повторить рассылку для получателей:';
				|en = 'The report distribution (%1) was not delivered to some recipients. Resend the reports to the following recipients:'; fa = 'The report distribution (%1) was not delivered to some recipients. Resend the reports to the following recipients:';
				|it = 'Рассылка отчетов (%1) была отправлена не всем получателям. Повторить рассылку для получателей:';
				|pl = 'The report distribution (%1) was not delivered to some recipients. Resend the reports to the following recipients:';
				|tr = 'Rapor bülteni (%1) tüm alıcılara gönderilmedi. Alıcılar için bülteni tekrarla:'"),
			MailoutStatus.LastRunStart);
	Else	
		Items.HeadingDecoration.Title = NStr("vi = 'Không cần gửi lại hàng loạt';
											|ru = 'Повторная рассылка не требуется.';
											|en = 'No need to resend the reports.'; fa = 'No need to resend the reports.';
											|it = 'Повторная рассылка не требуется.';
											|pl = 'No need to resend the reports.';
											|tr = 'Bültenin tekrarına gerek yoktur.'");
	EndIf;
	
	PopulateRedistributionRecipients(DistributionRef, MailoutStatus);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RedoDistribution(Command)
	
	If Recipients.Count() = 0 Then
		Return;
	EndIf;
	
	MailingArray = New Array;
	MailingArray.Add(DistributionRef);
	
	StartupParameters = New Structure("MailingArray, Form, IsItemForm");
	StartupParameters.MailingArray = MailingArray;
	StartupParameters.Form = FormOwner;
	StartupParameters.IsItemForm = (FormOwner = "Catalog.ReportMailings.Form.ItemForm");
	
	RecipientsList = New Map;
	For Each RecipientRow In Recipients Do
		RecipientsList.Insert(RecipientRow.Recipient, RecipientRow.Email);
	EndDo;
	
	ReportMailingClient.ExecuteNowInBackground(RecipientsList, StartupParameters);
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PopulateRedistributionRecipients(DistributionRef, MailoutStatus)
	
	RedistributionRecipients = ReportMailing.ReportRedistributionRecipients(DistributionRef,
		MailoutStatus.LastRunStart, MailoutStatus.SessionNumber);
	
	For Each Recipient In RedistributionRecipients Do
		RowRecipients = Recipients.Add();
		RowRecipients.Recipient = Recipient.Key;
		RowRecipients.Email = Recipient.Value;
	EndDo;

EndProcedure

#EndRegion
