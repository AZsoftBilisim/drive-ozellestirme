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
	Settings.Events.AfterQuickSettingsBarFilled = True;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
// 
// Parameters:
//   ThisForm - ClientApplicationForm - Report form
//   FillParameters - Structure, Undefined - 
//
Procedure AfterQuickSettingsBarFilled(ThisForm, FillParameters) Export
	
	If Not GetFunctionalOption("UseQualityCertificates") Then
		Return;
	EndIf;
	
	DataCompositionUserFields = ThisForm.Report.SettingsComposer.Settings.UserFields; // DataCompositionUserFields
	CertificateTypeField = DataCompositionUserFields.Items[0]; 
	DataLayoutFieldCertificateType = CertificateTypeField.Variants.Items[0].Filter.Items[0].LeftValue;
	CertificateTypeField.Variants.Items.Clear();
	
	ArrayOfCertificateTypes = Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	
	For Each CertificateType In ArrayOfCertificateTypes Do
		
		DataLayoutOption = CertificateTypeField.Variants.Items.Add();
		DataLayoutOption.Use = True;
		DataLayoutOption.Value = CertificateType;
		DataLayoutOption.Presentation = CertificateType;
		
		FilterElement = DataLayoutOption.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use  = True;
		FilterElement.LeftValue  = DataLayoutFieldCertificateType;
		FilterElement.ComparisonType   = DataCompositionComparisonType.Contains;
		FilterElement.RightValue = CertificateType;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf