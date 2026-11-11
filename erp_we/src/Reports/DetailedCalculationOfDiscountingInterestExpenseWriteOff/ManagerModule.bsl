#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = False;
	OptionSettings.LongDesc = NStr("vi = 'Bảng tính chi phí chiết khấu theo phần trăm.';
									|ru = 'Справка расчет начисления процентных расходов дисконтирования.';
									|en = 'Sheet of discounting interest expense charge.'; fa = 'Sheet of discounting interest expense charge.';
									|it = 'Certificato di enumerazione spese di interessi di sconto.';
									|pl = 'Informacje o naliczeniach kosztów odsetkowych dyskontowania.';
									|tr = 'İskonto edilen faiz giderleri tahakkukunun hesap özeti.'");
EndProcedure

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DetailedCalculationOfDiscountingInterestExpenseWriteOff)
		And HaveRightToReadDocumentTables() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DetailedCalculationOfDiscountingInterestExpenseWriteOff.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính ghi giảm chi phí chiết khấu theo phần trăm';
											|ru = 'Справка-расчет списания процентных расходов дисконтирования';
											|en = 'Sheet of discounting interest expense write-off'; fa = 'برگه اسقاط هزینه بهره تنزیل';
											|it = 'Certificato di storno spese di interessi di sconto';
											|pl = 'Informacje o rozchodach kosztów odsetkowych dyskontowania';
											|tr = 'İskonto faiz giderlerinin silinmesinin yardımcı hesaplaması'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ContextOption_";
	
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#Region Private

Function HaveRightToReadDocumentTables() 
	
	ArrayOfDocumentTypes_ = AccumulationRegisters.DiscountInterestExpense.GetTypesOfDocumentsInvolvedInDiscounting();
	
	For Each DocumentType In ArrayOfDocumentTypes_ Do
		
		DocumentRef = New(DocumentType);
		MetadataOfDocument = DocumentRef.Metadata();
		
		If MetadataOfDocument = Undefined 
			Or Not AccessRight("Read", MetadataOfDocument) Then
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf