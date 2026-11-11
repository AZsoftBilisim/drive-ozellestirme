#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
// 	ReportsCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
// Returns:
// 	Undefined, ValueTableRow - description of the added command.
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ControlOfRawAndConsumableMaterialsDeliveryToToller2_5) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ControlOfRawAndConsumableMaterialsDeliveryToToller2_5.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát việc chuyển nguyên vật liệu';
											|ru = 'Контроль передачи сырья и материалов';
											|en = 'Control of raw and consumable materials transfer'; fa = 'Control of raw and consumable materials transfer';
											|it = 'Controllo di consegna delle materie prime e dei materiali';
											|pl = 'Kontrola przekazania surowców i materiałów';
											|tr = 'Hammadde ve sarf malzemelerinin kontrolü'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ControlOfTransferOfRawMaterialsToProcessor2_5Context";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfRawAndConsumableMaterialsDeliveryToToller2_5);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Cần chuyển và đã chuyển bao nhiêu nguyên vật liệu cho người nhận gia công?';
									|ru = 'Сколько необходимо передать и передано материалов переработчикам?';
									|en = 'Check how many materials you need to transfer and are transferred to subcontractors.'; fa = 'Check how many materials you need to transfer and are transferred to subcontractors.';
									|it = 'Сколько необходимо передать и передано материалов переработчикам?';
									|pl = 'Ile należy przekazać i przekazano materiałów właścicielom surowców?';
									|tr = 'Fason üreticilere ne kadarlık malzeme transfer edilmeli ve ne kadarı transfer edildi?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfRawAndConsumableMaterialsDeliveryToToller2_5");
	OptionDetails.LongDesc = NStr("vi = 'Cần chuyển và đã chuyển bao nhiêu nguyên vật liệu cho người nhận gia công?';
									|ru = 'Сколько необходимо передать и передано материалов переработчикам?';
									|en = 'Check how many materials you need to transfer and are transferred to subcontractors.'; fa = 'Check how many materials you need to transfer and are transferred to subcontractors.';
									|it = 'Сколько необходимо передать и передано материалов переработчикам?';
									|pl = 'Ile należy przekazać i przekazano materiałów właścicielom surowców?';
									|tr = 'Fason üreticilere ne kadarlık malzeme transfer edilmeli ve ne kadarı transfer edildi?'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOfTransferOfRawMaterialsToProcessor2_5Context");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf