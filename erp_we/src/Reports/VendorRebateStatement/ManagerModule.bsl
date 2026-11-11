// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	DisplayReportOptions = False;
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorRebateStatement);
	ReportSettings.FunctionalOptions.Add(Metadata.FunctionalOptions.UseVendorRebates.Name);
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "VendorRebateStatement");
	OptionSettings.LongDesc = NStr("vi = 'Có bao nhiêu tiền thưởng đã được tính và cấp bởi nhà cung cấp trong kỳ chỉ định?
									  |Có bao nhiêu tiền thưởng được phản ánh bởi biên ban thưởng tài chính hoặc đang chờ thống nhất chứng từ ghi giảm?
									  |Số dư thưởng lũy kế đã tính theo nhà cung cấp là bao nhiêu?';
									  |ru = 'Сколько бонусов начислено поставщиками за указанный период?
									  |Какие суммы бонусов отражены актом финансовой премии или ожидают согласования документов списания?
									  |Какой остаток начисленных ретро-бонусов от поставщиков?';
									  |en = 'How many rebates were accrued by vendors during the specified period?
									  |What rebate amounts are registered by the financial bonus certificate or pending approval of write-off documents?
									  |What is the balance of accrued rebates from vendors?'; fa = 'How many rebates were accrued by vendors during the specified period?
									  |What rebate amounts are registered by the financial bonus certificate or pending approval of write-off documents?
									  |What is the balance of accrued rebates from vendors?';
									  |it = 'Сколько бонусов начислено поставщиками за указанный период?
									  |Какие суммы бонусов отражены актом финансовой премии или ожидают согласования документов списания?
									  |Какой остаток начисленных ретро-бонусов от поставщиков?';
									  |pl = 'How many rebates were accrued by vendors during the specified period?
									  |What rebate amounts are registered by the financial bonus certificate or pending approval of write-off documents?
									  |What is the balance of accrued rebates from vendors?';
									  |tr = 'Belirtilen dönem için tedarikçilere kaç ikramiye tahakkuk ettirilmiş ve verilmiştir? 
									  |Mali ikramiye belgelerinin imzalanmasını veya mahsup belgelerinin onaylanmasını bekleyen ikramiye tutarları nedir? 
									  |Tedarikçiler tarafından tahakkuk ettirilen retro ikramiye bakiyesi nedir?'");
	OptionSettings.Location.Insert(Metadata.Subsystems.Purchases.Subsystems.VendorRebates);
	
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, DisplayReportOptions);
	
	TMReportOptionsOverridable.DisableReportOption(
		Settings,
		ReportSettings,
		"StatementOnDeferredExpensedContextOfCondition");
		
	TMReportOptionsOverridable.DisableReportOption(
		Settings,
		ReportSettings,
		"StatementOnDeferredExpensedContextActOfAward");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.VendorRebateStatement)
	   And GetFunctionalOption("UseVendorRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		Presentation = NStr("vi = 'Bảng kê thưởng lũy kế đã tính';
							|ru = 'Ведомость по начисленным ретро-бонусам';
							|en = 'Accrued rebate statement'; fa = 'Accrued rebate statement';
							|it = 'Ведомость по начисленным ретро-бонусам';
							|pl = 'Accrued rebate statement';
							|tr = 'Tahakkuk eden retro-bonus tablosu'");
		ReportCommand.Manager = Metadata.Reports.VendorRebateStatement.FullName();
		ReportCommand.Presentation = Presentation;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		If ValueIsFilled(VariantKey) Then
			
			ReportCommand.VariantKey = VariantKey;
			
		EndIf;
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region Private

// Parameters:
//  AreasWithTranscripts - Structure:
//   * ArrayOfDecryptionIds - Array of DataCompositionDetailsID
//   * Decryption_Area - Map of KeyAndValue:
//     ** Key - DataCompositionDetailsID
//     ** Value - String - Area name
//  DetailsDataAddress - String
//  DecryptionFields - Array of String
//  Action-String
// 
// Returns:
//  Structure:
//   * ArrayOfConditionDocuments - Array of DocumentRef.ConditionsOfVendorRebates
//   * ArrayOfAreaNames - Array of String
//   * TermsAndConditionsDocumentsWithAddresses - Map of KeyAndValue:
//      ** Key - String
//      ** Value - DocumentRef.ConditionsOfVendorRebates
//
Function DocumentsConditionsOfSelectedAreas(AreasWithTranscripts, DetailsDataAddress, DecryptionFields) Export
	
	DetailsData = GetFromTempStorage(DetailsDataAddress); // DataCompositionDetailsData
	
	Decryption_Area = AreasWithTranscripts.Decryption_Area;
	ArrayOfDecryptionIds = AreasWithTranscripts.ArrayOfDecryptionIds;
	
	DocumentType = Type("DocumentRef.ConditionsOfVendorRebates");
	ArrayOfConditionDocuments = New Array; // Array of DocumentRef.ConditionsOfVendorRebates
	ArrayOfAreaNames = New Array; // Array of String
	TermsAndConditionsDocumentsWithAddresses = New Map;
	
	For Each CurrentDrilldown In ArrayOfDecryptionIds Do
		
		DecryptionField = DetailsData.Items.Get(CurrentDrilldown).GetFields()[0];
		If TypeOf(DecryptionField.Value) = DocumentType
		   And ValueIsFilled(DecryptionField.Value) Then
			
			TermDocument = DecryptionField.Value; // DocumentRef.ConditionsOfVendorRebates
			
			AreaName = Decryption_Area[CurrentDrilldown];
			ArrayOfAreaNames.Add(AreaName);
			TermsAndConditionsDocumentsWithAddresses.Insert(AreaName, TermDocument);
			
			If ArrayOfConditionDocuments.Find(TermDocument) = Undefined Then
				ArrayOfConditionDocuments.Add(TermDocument);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("ArrayOfConditionDocuments", ArrayOfConditionDocuments);
	Result.Insert("ArrayOfAreaNames", ArrayOfAreaNames);
	Result.Insert("TermsAndConditionsDocumentsWithAddresses", TermsAndConditionsDocumentsWithAddresses);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf