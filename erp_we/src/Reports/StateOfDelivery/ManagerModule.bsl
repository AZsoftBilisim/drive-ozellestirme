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
	
	ReportSettings.FunctionalOptions.Add("NotUseDeliveryManagement20");
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "StateOfDelivery");
	OptionSettings.Description = NStr("ru = 'Состояние доставки';
										|vi = 'Delivery state';
										|en = 'Delivery state'; fa = 'وضعیت تحویل';
										|it = 'Delivery state';
										|pl = 'Delivery state';
										|tr = 'Teslimat durumu'");
	OptionSettings.LongDesc = NStr("ru = 'Анализ запланированной доставки по документам.
											|По каким товарам и в каком количестве требуется доставка?
											|Для каких товаров необходимо планирование рейса?';
											|vi = 'Analysis of planned delivery based on documents.
											|For which goods and in what quantity is delivery required?
											|For which goods is trip planning necessary?';
											|en = 'Analysis of planned delivery based on documents.
											|For which goods and in what quantity is delivery required?
											|For which goods is trip planning necessary?'; fa = 'Analysis of planned delivery based on documents.
											|For which goods and in what quantity is delivery required?
											|For which goods is trip planning necessary?';
											|it = 'Analysis of planned delivery based on documents.
											|For which goods and in what quantity is delivery required?
											|For which goods is trip planning necessary?';
											|pl = 'Analysis of planned delivery based on documents.
											|For which goods and in what quantity is delivery required?
											|For which goods is trip planning necessary?';
											|tr = 'Belgelere göre planlanan teslimat analizi.
											|Hangi mallar için ve hangi miktarda teslimat gerekiyor? 
											| Hangi mallar için sefer planlaması gerekli?'");
	OptionSettings.Location.Insert(Metadata.Subsystems.Warehouse.Subsystems.DeliveryManagement);
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "StateOfDeliveryOfGoods");
	OptionSettings.Description = NStr("ru = 'Состояние доставки (по товарам)';
										|vi = 'Delivery state (by goods)';
										|en = 'Delivery state (by goods)'; fa = 'وضعیت تحویل (بر اساس کالا)';
										|it = 'Delivery state (by goods)';
										|pl = 'Delivery state (by goods)';
										|tr = 'Teslimat durumu (mallara göre)'");
	OptionSettings.Location.Insert(Metadata.Subsystems.Warehouse.Subsystems.DeliveryManagement);
	
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, True);
	
	TMReportOptionsOverridable.DisableReportOption(Settings, ReportSettings, "DeliveryStateContext");
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

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
	
	ReportCommand = Undefined;
	
	If AccessRight("View", Metadata.Reports.StateOfDelivery) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StateOfDelivery.FullName();
		ReportCommand.Presentation = NStr("ru = 'Состояние доставки';
											|vi = 'Delivery state';
											|en = 'Delivery state'; fa = 'وضعیت تحویل';
											|it = 'Delivery state';
											|pl = 'Delivery state';
											|tr = 'Teslimat durumu'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.WriteMode = "Post";
		ReportCommand.FunctionalOptions = "NotUseDeliveryManagement20";
		ReportCommand.Importance = "Ordinary";
		
		If ValueIsFilled(VariantKey) Then
			
			ReportCommand.VariantKey = VariantKey;
			
		EndIf;
		
	EndIf;
	
	Return ReportCommand;
	
EndFunction

#EndRegion

#EndRegion

#EndIf