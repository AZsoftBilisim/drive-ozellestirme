#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//   	* Parameters - Structure - The parameter structure contains, among other things:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure:
//   				**** CommandName - String
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
			
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "CustomerOrderApprovalResults" Then
			ThisForm.ParametersForm.Filter.Insert("SubjectOf", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ResultsOfApprovalOfCommercialOffer" Then
			ThisForm.ParametersForm.Filter.Insert("SubjectOf", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "SaleApprovalResults" Then
			Subjects = Common.ObjectsAttributeValue( Parameters.CommandParameter, "SubjectOf");
			For Each CurItem In Subjects Do
				If Not ValueIsFilled(CurItem.Value) Then
					ErrorText = NStr("vi = 'Trong quy trình kinh doanh %1, một mục không được điền. Báo cáo sẽ không được tạo.';
									|ru = 'В бизнес-процессе %1 не заполнен предмет. Отчет не будет сформирован.';
									|en = 'Subject in business process %1 is not filled in. The report will not be generated.'; fa = 'Subject in business process %1 is not filled in. The report will not be generated.';
									|it = 'Nel processo aziendale %1 non è compilato l''oggetto. Il report non verrà generato.';
									|pl = 'W procesie biznesowym %1 nie jest wypełniony przedmiot. Raport nie zostanie wygenerowany.';
									|tr = 'Konu %1 iş sürecinde tamamlanmamıştır. Rapor oluşturulmayacaktır.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, CurItem.Key);
					CommonClientServer.MessageToUser(ErrorText);
					Cancel = True;
				EndIf;
			EndDo;
			ThisForm.ParametersForm.Filter.Insert("SaleApproval", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ResultsOfAgreementApprovalWithClients" Then
			ThisForm.ParametersForm.Filter.Insert("SubjectOf", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf