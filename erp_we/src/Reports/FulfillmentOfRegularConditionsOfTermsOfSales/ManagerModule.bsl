#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddFulfillmentOfTermsOfAgreementsWithClientsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.FulfillmentOfRegularConditionsOfTermsOfSales) 
			And GetFunctionalOption("ToUseTermsOfSales") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.FulfillmentOfRegularConditionsOfTermsOfSales.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thực hiện điều kiện thường xuyên';
											|ru = 'Выполнение регулярных условий';
											|en = 'Fulfillment of regular conditions'; fa = 'Fulfillment of regular conditions';
											|it = 'Soddisfazione delle condizioni standard';
											|pl = 'Wykonywanie regularnych warunków';
											|tr = 'Düzenli koşulların uygunluğu'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.AdditionalParameters.Insert("CommandName", "FulfillmentOfRegularConditionsOfTermsOfSales");
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddFulfillmentOfTermsOfAgreementsWithClientsForPartnerTeam(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.FulfillmentOfRegularConditionsOfTermsOfSales) 
			And GetFunctionalOption("ToUseTermsOfSales") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.FulfillmentOfRegularConditionsOfTermsOfSales.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thực hiện điều kiện thường xuyên của thỏa thuận';
											|ru = 'Выполнение регулярных условий соглашений';
											|en = 'Deviations from sales terms'; fa = 'Deviations from sales terms';
											|it = 'Soddisfare i termini del contratto standard';
											|pl = 'Spełnianie regularnych warunków umowy';
											|tr = 'Anlaşmaların düzenli koşullarını yerine getirme'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
		ReportCommand.AdditionalParameters.Insert("CommandName", "FulfillmentOfTermsOfAgreementsWithClientsOnPartner");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FulfillmentOfRegularConditionsOfTermsOfSales);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc khách hàng thực hiện các điều kiện thỏa thuận, trong đó có ghi nhận các điều kiện bán hàng thường xuyên.';
									|ru = 'Контроль выполнения клиентами условий соглашений, в которых заданы регулярные условия продаж.';
									|en = 'Control of customer''s compliance with the standard terms of sales.'; fa = 'Control of customer''s compliance with the standard terms of sales.';
									|it = 'Контроль выполнения клиентами условий соглашений, в которых заданы регулярные условия продаж.';
									|pl = 'Kontrola wykonania przez klientów warunków umowy, w których są zadane regularne warunki sprzedaży.';
									|tr = 'İstemcilerin, düzenli satış koşullarını belirleyen anlaşma şartlarının yürütülmesinin kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc khách hàng thực hiện các điều kiện thỏa thuận, trong đó có ghi nhận các điều kiện bán hàng thường xuyên.';
									|ru = 'Контроль выполнения клиентами условий соглашений, в которых заданы регулярные условия продаж.';
									|en = 'Control of customer''s compliance with the standard terms of sales.'; fa = 'Control of customer''s compliance with the standard terms of sales.';
									|it = 'Контроль выполнения клиентами условий соглашений, в которых заданы регулярные условия продаж.';
									|pl = 'Kontrola wykonania przez klientów warunków umowy, w których są zadane regularne warunki sprzedaży.';
									|tr = 'İstemcilerin, düzenli satış koşullarını belirleyen anlaşma şartlarının yürütülmesinin kontrolü.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf