#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ItemsDetails = Parameters.ItemsDetails;
	Partner = Parameters.Partner;
	Counterparty = Parameters.Counterparty;
	
	GenerateComposerSettings();
	
	Period = "In references_5 for_ day";
	
	Items.CharacteristicsDetails.Visible = ItemsDetails;

	Items.Period.ChoiceList.Clear();
	GenerateListOfPeriods();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure PeriodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ResultStructure1 = New  Structure;
	ResultStructure1.Insert("Period", Period);
	ResultStructure1.Insert("BeginOfPeriod", SalesHistoryAnalysisPeriod.StartDate);
	ResultStructure1.Insert("EndOfPeriod", SalesHistoryAnalysisPeriod.EndDate);
	ResultStructure1.Insert("Settings", ComposerSettings());
	ResultStructure1.Insert("CharacteristicsDetails", CharacteristicsDetails);
	
	Close(ResultStructure1);
	
EndProcedure

&AtClient
Procedure SelectAnalysisPeriodOfSalesHistory()
	
	PeriodSelection();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PeriodSelection()

	Dialog = New StandardPeriodEditDialog();
	Dialog.Period = SalesHistoryAnalysisPeriod;
	Dialog.Show(New CallbackDescription("PeriodSelectionCompletion", ThisObject, New Structure("Dialog", Dialog)));

EndProcedure

&AtClient
Procedure PeriodSelectionCompletion(Period1, AdditionalParameters) Export
    
    Dialog = AdditionalParameters.Dialog;
        
    If Period1 <> Undefined Then 
        SalesHistoryAnalysisPeriod = Dialog.Period;		
    EndIf;

EndProcedure

&AtServer
Procedure GenerateListOfPeriods()

	Items.Period.ChoiceList.Add("In references_5 for_ day", NStr("vi = 'trung bình trong ngày';
																|ru = 'в среднем за день';
																|en = 'daily average'; fa = 'daily average';
																|it = 'in media al giorno';
																|pl = 'przeciętnie za dzień';
																|tr = 'Günlük ortalama tüketim'"));
    Items.Period.ChoiceList.Add("In references_5 for_ aweek", NStr("vi = 'trung bình trong tuần';
																	|ru = 'в среднем за неделю';
																	|en = 'weekly average'; fa = 'weekly average';
																	|it = 'in media a settimana';
																	|pl = 'przeciętnie za tydzień';
																	|tr = 'haftalık ortalama tüketim'"));
    Items.Period.ChoiceList.Add("In references_5 for_ month", NStr("vi = 'trung bình trong tháng';
																	|ru = 'в среднем за месяц';
																	|en = 'monthly average'; fa = 'monthly average';
																	|it = 'in media al mese';
																	|pl = 'przeciętnie za miesiąc';
																	|tr = 'aylık ortalama tüketim'"));

EndProcedure

&AtServer
Procedure GenerateComposerSettings()
	
	If ItemsDetails Then
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistory");
	Else
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistoryByAmount");
	EndIf;	

	CompositionSettings = CompositionSchema.DefaultSettings;
	
	Address = New UUID();
	URLSchemes = PutToTempStorage(CompositionSchema, Address);
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(CompositionSettings);
	PartnersAndCounterparties.DeleteItemFromReportSelectionSettings(SettingsComposer, "Counterparty");
	SetSelectionElementValues(SettingsComposer.Settings.Filter);
	
EndProcedure

&AtServer
Procedure SetSelectionElementValues(Filter)

	PartnerLayoutField = New DataCompositionField("Partner");
	CounterpartyLayoutField = New DataCompositionField("Counterparty");
	
	For Each FilterElement In Filter.Items Do
		
		If FilterElement.LeftValue = PartnerLayoutField Then

            FilterElement.RightValue = Partner;
            FilterElement.Use = ValueIsFilled(Partner);

		ElsIf FilterElement.LeftValue = CounterpartyLayoutField Then

            FilterElement.RightValue = Counterparty;
            FilterElement.Use = ValueIsFilled(Counterparty);

		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Function ComposerSettings()
	
	Return SettingsComposer.GetSettings();
	
EndFunction

#EndRegion
