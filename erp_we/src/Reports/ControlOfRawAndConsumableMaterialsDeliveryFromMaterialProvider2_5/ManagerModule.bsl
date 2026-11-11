#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//
// Parameters:
//  ReportsCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
//
// Returns:
//  Undefined, ValueTableRow - description of the added command.
//
Function AddReportCommand(ReportsCommands) Export
	
	If Not AccessRight("View", Metadata.Reports.ControlOfRawAndConsumableMaterialsDeliveryFromMaterialProvider2_5) Then
		Return Undefined;
	EndIf;
	
	ReportCommand = ReportsCommands.Add();
	ReportCommand.Manager           = Metadata.Reports.ControlOfRawAndConsumableMaterialsDeliveryFromMaterialProvider2_5.FullName();
	ReportCommand.Presentation      = NStr("vi = 'Kiểm soát việc cung cấp nguyên vật liệu bởi bên đặt gia công';
											|ru = 'Контроль поставки сырья и материалов давальцем';
											|en = 'Control of raw and consumable materials delivery from material provider'; fa = 'کنترل تحویل مواد اولیه و مصرفی از تأمین‌کننده مواد';
											|it = 'Controllo di consegna delle materie prime e dei materiali dal prestatore';
											|pl = 'Kontrola dostawy surowców i materiałów przez właściciela surowców';
											|tr = 'Sağlayıcı tarafından hammadde ve malzeme tedariki kontrolü'");
	ReportCommand.MultipleChoice = False;
	ReportCommand.Importance           = "Ordinary";
	ReportCommand.VariantKey       = "ControlOfSupplyOfRawMaterialsAndMaterialsByGiver2_5Context";
	
	Return ReportCommand;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfRawAndConsumableMaterialsDeliveryFromMaterialProvider2_5);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Cần tiếp nhận và đã tiếp nhận bao nhiêu nguyên vật liệu từ người đặt gia công?';
									|ru = 'Сколько должно поступить и поступило материалов от давальцев?';
									|en = 'Check how many materials are expected and received from providers.'; fa = 'Check how many materials are expected and received from providers.';
									|it = 'Сколько должно поступить и поступило материалов от давальцев?';
									|pl = 'Ile powinno wpłynąć i wpłynęło materiałów od właścicieli surowców?';
									|tr = 'Tedarikçilerden ne kadar malzeme alınmalı ve alındı?'");
		
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfRawAndConsumableMaterialsDeliveryFromMaterialProvider2_5");
	OptionDetails.LongDesc = NStr("vi = 'Cần tiếp nhận và đã tiếp nhận bao nhiêu nguyên vật liệu từ người đặt gia công?';
									|ru = 'Сколько должно поступить и поступило материалов от давальцев?';
									|en = 'Check how many materials are expected and received from providers.'; fa = 'Check how many materials are expected and received from providers.';
									|it = 'Сколько должно поступить и поступило материалов от давальцев?';
									|pl = 'Ile powinno wpłynąć i wpłynęło materiałów od właścicieli surowców?';
									|tr = 'Tedarikçilerden ne kadar malzeme alınmalı ve alındı?'");
		
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOfSupplyOfRawMaterialsAndMaterialsByGiver2_5Context");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf