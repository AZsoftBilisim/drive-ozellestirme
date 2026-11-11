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
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	If ThisForm.Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("Document", ThisForm.Parameters.CommandParameter);
	EndIf;
	
	Parameters = ThisForm.ParametersForm;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Document") Then
		
		If TypeOf(Parameters.Filter.Document) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
			Attributes = Documents.CustomerInvoiceIntercompany.DocumentAttributes(Parameters.Filter.Document);
			
			Parameters.Filter.Insert("Sender",	Attributes.SenderOrganization);
			Parameters.Filter.Insert("Recipient",	Attributes.CompanyRecipient);
			
		ElsIf TypeOf(Parameters.Filter.Document) = Type("DocumentRef.CommissionReportIntercompany")
			Or TypeOf(Parameters.Filter.Document) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
			
			If TypeOf(Parameters.Filter.Document) = Type("DocumentRef.CommissionReportIntercompany") Then
				Attributes = Documents.CommissionReportIntercompany.DocumentAttributes(Parameters.Filter.Document);
			Else
				Attributes = Documents.CommissionWriteOffReportIntercompany.DocumentAttributes(Parameters.Filter.Document);
			EndIf;
			
			Parameters.Filter.Insert("Consignor",	Attributes.SenderOrganization);
			Parameters.Filter.Insert("Consignee",	Attributes.CompanyRecipient);
			
			If ValueIsFilled(Attributes.BeginOfPeriod)
				Or ValueIsFilled(Attributes.EndOfPeriod) Then
				
				Period = New StandardPeriod;
				Period.Variant			= StandardPeriodVariant.Custom;
				Period.StartDate		= Attributes.BeginOfPeriod;
				Period.EndDate	= Attributes.EndOfPeriod;
				
				Parameters.Filter.Insert("Period", Period);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
