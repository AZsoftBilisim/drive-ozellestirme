
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TypeOfCall			= Parameters.TypeOfCall;
	TransmittedTable 	= GetFromTempStorage(Parameters.AddressInStorage);	
	AdditionalParameters	= New Structure();

	If Parameters.Property("AdditionalParameters", AdditionalParameters) And AdditionalParameters.Count() Then
		FillPropertyValues(ThisObject, AdditionalParameters);
	EndIf;
	
	FillInTableOfValuesFromTransmittedData(TransmittedTable);	
	
	CustomizeForm();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceRoundingRules

&AtClient
Procedure PriceRoundingRulesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		If PriceRoundingRules.Count() > 1 Then
			
			BasicBorderValue = PriceRoundingRules[PriceRoundingRules.Count() - 2].LowerBoundOfPriceRange ;
			
			If Not ValueIsFilled(BasicBorderValue) Then
				BasicBorderValue = 1;
			EndIf;
			
			Item.CurrentData.LowerBoundOfPriceRange = BasicBorderValue * 10;
			
		EndIf;
		
		ConfigureTableRoundingRule();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LowerBoundOfPriceRangeOnChange(Item)
	
	ConfigureTableRoundingRule();
	
EndProcedure

&AtClient
Procedure PriceRoundingRulesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	ClearMessages();
	
	If Not CancelEdit Then
		
		For Each StringOfRoundingRules In PriceRoundingRules Do
			
			If StringOfRoundingRules <> Item.CurrentData 
				And StringOfRoundingRules.LowerBoundOfPriceRange = Item.CurrentData.LowerBoundOfPriceRange Then
				
				Message = NStr("vi = 'Đối với khoảng từ %LowerBound% đã đặt quy tắc làm tròn.';
								|ru = 'Для диапазона от %LowerBound% уже заданы правила округления.';
								|en = 'Rounding rules are already specified for the range from %LowerBound%.'; fa = 'Rounding rules are already specified for the range from %LowerBound%.';
								|it = 'Per un intervallo da %LowerBound% le regole di arrotondamento sono già impostate.';
								|pl = 'Dla zakresu od %LowerBound% określono już reguły zaokrąglania.';
								|tr = '%LowerBound% aralığında zaten yuvarlama kuralları belirtilmiş.'");
				LowerBoundValue = Item.CurrentData.LowerBoundOfPriceRange;
				
				If ValueIsFilled(PriceCurrency) Then
					LowerBoundValue = String(LowerBoundValue) + " " + PriceCurrency;
				EndIf;
				
				Message = StrReplace(Message, "%LowerBound%", LowerBoundValue);
				CommonClientServer.MessageToUser(Message, , , CommonClientServer.PathToTabularSection("PriceRoundingRules", PriceRoundingRules.IndexOf(Item.CurrentData) + 1, "LowerBoundOfPriceRange"), Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceRoundingRulesAfterDeleteRow(Item)
	
	ConfigureTableRoundingRule();
	
EndProcedure

&AtClient
Procedure PriceRoundingRulesOnChange(Item)
	
	ConfigureTableRoundingRule();
	
EndProcedure

&AtClient
Procedure RoundOffOptionOnChange(Item)
	
	
	ConfigureTableRoundingRule();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFormulae

&AtClient
Procedure PriceGroupsFormulaStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing    = False;
	EditResult = Undefined;

	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersOfPriceEditingForm(Items.PriceGroups.CurrentData.Formula), Item,,,, New CallbackDescription("PriceGroupsFormulaStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PriceGroupsFormulaStartChoiceCompletion(Result, AdditionalParameters) Export
    
    EditResult = Result;
    
    If EditResult <> Undefined Then
        Items.PriceGroups.CurrentData.Formula = EditResult;
        Modified = True;
    EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)

	AddressInStorage = PlaceTableInRepository();
	
	AdditionalParameters = New Structure;	
	
	If TypeOfCall = "RefinementOfRoundingSettings" Then		
		AdditionalParameters.Insert("RoundOffOption", RoundOffOption);	
	EndIf;
	
	ParametersStructure = New Structure("AddressInStorage, TypeOfCall, AdditionalParameters", AddressInStorage, TypeOfCall, AdditionalParameters);
	
	Close(ParametersStructure);
	
EndProcedure

&AtClient
Procedure RoundingConstructor()
	
	StringOfRoundingRules = Items.PriceRoundingRules.CurrentData;
	
	If StringOfRoundingRules = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
										|ru = 'Команда не может быть выполнена для указанного объекта!';
										|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
										|it = 'Il comando non può essere eseguito per oggetto indicato!';
										|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
										|tr = 'Belirtilen nesne için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	
	UpperBoundOfRange  = UpperLimitOfPriceRange(StringOfRoundingRules);
	IDOfRoundingRuleString = StringOfRoundingRules.GetID();

	If ValueIsFilled(StringOfRoundingRules.RoundingPrecision)
		And (StringOfRoundingRules.RoundingPrecision < UpperBoundOfRange)
			Or UpperBoundOfRange = -1 Then
		UpperBoundOfRange = StringOfRoundingRules.RoundingPrecision;
	EndIf;
	
	EditResult = Undefined;
	
	FormParameters = New Structure;
	FormParameters.Insert("RoundingPrecision", StringOfRoundingRules.RoundingPrecision);
	FormParameters.Insert("RoundOffOption", RoundOffOption);
	FormParameters.Insert("SmartRounding", StringOfRoundingRules.SmartRounding);
	FormParameters.Insert("PriceRangeBoundary", UpperBoundOfRange);
	FormParameters.Insert("ExampleNumber", StringOfRoundingRules.LowerBoundOfPriceRange);
	
	OpenForm("Catalog.TypesOfPrices.Form.SmartRoundingConstructorForm", 
		FormParameters,,,,,
		New CallbackDescription("RoundingConstructorCompletion",
			ThisObject,
			New Structure("StringOfRoundingRules", StringOfRoundingRules)),
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure RoundingConstructorCompletion(Result, AdditionalParameters) Export
    
    StringOfRoundingRules = AdditionalParameters.StringOfRoundingRules;
    
    
    EditResult = Result;
    
    If EditResult <> Undefined Then
        StringOfRoundingRules.SmartRounding = EditResult.SmartRounding;
        StringOfRoundingRules.RoundingPrecision = EditResult.RoundingPrecision;
        RoundOffOption = EditResult.RoundOffOption;
        
        ConfigureTableRoundingRule();
    EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTableOfValuesFromTransmittedData(TransmittedTable)
	
	
	If StrStartsWith(TypeOfCall, "ClarificationByPriceGroup") Then
		
		CurrentTable = PriceGroups;

	ElsIf TypeOfCall = "SpecifyingCurrenciesByPriceGroup" Then
		 
		CurrentTable = Currencies;

	ElsIf TypeOfCall = "RefinementOfResponseThresholds" Then
		 
		CurrentTable = Thresholds;
		
	ElsIf TypeOfCall = "RefinementOfRoundingSettings" Then
		 
		CurrentTable = PriceRoundingRules;
		
	ElsIf TypeOfCall = "ClarificationOfPercentagesOfDiscountsMargins" Then
		 
		CurrentTable = MaximumPercentagesOfDiscountsMarkups;
		
	EndIf;
	
	CurrentTable.Clear();	
	CurrentTable.Load(TransmittedTable);
	
EndProcedure

&AtServer
Procedure AdjustVisibilityAccessibilityHeader()	
	
	HeaderOfConfigurationForm = NStr("vi = 'Xác định %1';
									|ru = 'Уточнение %1';
									|en = 'Clarification %1'; fa = 'Clarification %1';
									|it = 'Precisazione %1';
									|pl = 'Uściślenie %1';
									|tr = 'İyileştirme %1'");
	
	If TypeOfCall = "ClarificationByPriceGroup_MarkUpForDifferentTypeOfPrice" Then
		
		ThisForm.Items.GroupPriceGroups.Visible 		= True;

		ThisForm.Items.PriceGroupsBasicPriceType.Visible = True;
		ThisForm.Items.PriceGroupsMarkup.Visible        = True;
		
		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "ofmargins to1 other kind prices_ on price tofolders");
		
	ElsIf TypeOfCall = "ClarificationByPriceGroup_MarkUpOnReceiptPrice" Then
		 
		ThisForm.Items.GroupPriceGroups.Visible 		= True;

		ThisForm.Items.PriceGroupsMarkup.Visible        = True;
		
		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "ofmargins to1 price_0 inflow on price tofolders");
		
	ElsIf TypeOfCall = "ClarificationByPriceGroups_CalculateByFormulasFromOtherTypesOfPrices" Then
		 
		ThisForm.Items.GroupPriceGroups.Visible 		= True;

		ThisForm.Items.PriceGroupsFormula.Visible        = True;;
		
		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "formulas_ on price tofolders");
		
	ElsIf TypeOfCall = "SpecifyingCurrenciesByPriceGroup" Then
		 
		ThisForm.Items.CurrenciesGroup.Visible 				= True;

		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "ofcurrencies on price tofolders");
		
	ElsIf TypeOfCall = "RefinementOfResponseThresholds" Then
		 
		ThisForm.Items.TriggerThresholdsGroup.Visible    = True;
		
		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "thresholds_ triggers on price tofolders");
		
	ElsIf TypeOfCall = "RefinementOfRoundingSettings" Then
		 
		ThisForm.Items.GroupPriceRoundingRules.Visible = True;
		
		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "rounding_ on price ranges_");
		
	ElsIf TypeOfCall = "ClarificationOfPercentagesOfDiscountsMargins" Then
		 
		ThisForm.Items.GroupPercentagesOfDiscountsMarkups.Visible = True;
		
		HeaderOfConfigurationForm = StrReplace(HeaderOfConfigurationForm, "%1", "maximum_ percent_ ofdiscounts (ofmargins) on price tofolders");
		
	EndIf;

	// The header of the form
	Title = HeaderOfConfigurationForm;	
	
EndProcedure


// Places a table of values with the selected changes in temporary storage
// and returns the address.
// 
// Returns:
//	String - the address of the value storage of the value table in the temporary storage.
//
&AtServer 
Function PlaceTableInRepository()

	If StrStartsWith(TypeOfCall, "ClarificationByPriceGroup") Then
		
		CurrentTable = PriceGroups.Unload();

	ElsIf TypeOfCall = "SpecifyingCurrenciesByPriceGroup" Then
		 
		CurrentTable = Currencies.Unload();

	ElsIf TypeOfCall = "RefinementOfResponseThresholds" Then
		 
		CurrentTable = Thresholds.Unload();
		
	ElsIf TypeOfCall = "RefinementOfRoundingSettings" Then
		 
		CurrentTable = PriceRoundingRules.Unload();
		
	ElsIf TypeOfCall = "ClarificationOfPercentagesOfDiscountsMargins" Then
		 
		CurrentTable = MaximumPercentagesOfDiscountsMarkups.Unload();
		
	EndIf;
	
	
	AddressOfAccessibilitySettings = PutToTempStorage(CurrentTable, ThisForm.UUID);
	
	Return AddressOfAccessibilitySettings;
	
EndFunction

&AtClient
Procedure PriceRoundingRulesOnActivateCell(Item)
	
	If Not Item.CurrentItem = Items.RoundingPrecision Then
		Return;
	EndIf;
	
	// Forming a selection list for the Roundness field
	Items.RoundingPrecision.ChoiceList.Clear();
	RoundingValue             = 0.01;
	EvenIncrement               = False;
	MaximumRoundingValue = 1000;
	PriceRangeBoundary            = UpperLimitOfPriceRange(Items.PriceRoundingRules.CurrentData);
	
	While RoundingValue <= MaximumRoundingValue 
		And (RoundingValue <= PriceRangeBoundary Or PriceRangeBoundary < 0) Do
		
		Items.RoundingPrecision.ChoiceList.Add(RoundingValue);
		RoundingValue = RoundingValue * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
EndProcedure


&AtClient
Function UpperLimitOfPriceRange(StringOfRoundingRules)
	
	IndexOf = PriceRoundingRules.IndexOf(StringOfRoundingRules);
	
	If IndexOf < PriceRoundingRules.Count() - 1 Then
		Return PriceRoundingRules[IndexOf + 1].LowerBoundOfPriceRange;
	EndIf;
	
	Return -1;
	
EndFunction


&AtClientAtServerNoContext
Procedure SetExample(Form, IndexOf)
	
	Number = 1111.11;
	If Form.PriceRoundingRules.Count() > 1 Then
		LowerBound = Form.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange;
		If IndexOf = Form.PriceRoundingRules.Count() - 1 Then
			UpperBound = LowerBound + 1000;
		Else
			UpperBound = Form.PriceRoundingRules[IndexOf+1].LowerBoundOfPriceRange;
		EndIf;
		Number = LowerBound + Round((UpperBound - LowerBound)/2, 15, 2);
		If Number + 0.11 < UpperBound Then
			Number = Number + 0.11;
		EndIf;
	EndIf;
	
	If Form.PriceRoundingRules[IndexOf].RoundingPrecision <> 0 Or Form.PriceRoundingRules[IndexOf].SmartRounding <> 0 Then
		Price = PriceManagementSystemClientServer.RoundUpPrice(Number, Form.PriceRoundingRules[IndexOf].RoundingPrecision, Form.RoundOffOption);
		Value = PriceManagementSystemClientServer.ApplyPsychologicalRounding(
			Price,
			Form.PriceRoundingRules[IndexOf].SmartRounding);
		
		FormatString = "NFD=2; NGS=' '; NZ=; NG=0";
		Form.PriceRoundingRules[IndexOf].ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Làm tròn %1 đến %2';
				|ru = 'Округлять %1 до %2';
				|en = 'Round %1 to %2'; fa = 'Round %1 to %2';
				|it = 'Arrotondare %1 fino a %2';
				|pl = 'Zaokrąglaj %1 do %2';
				|tr = '%1 değerini %2 boyunca yuvarla'"),
			Format(Number, FormatString),
			Format(Value, FormatString));
	Else
		Form.PriceRoundingRules[IndexOf].ToolTip = NStr("vi = 'Không làm tròn';
														|ru = 'Не округлять';
														|en = 'Do not round off'; fa = 'Do not round off';
														|it = 'Non arrotondare';
														|pl = 'Nie zaokrąglaj';
														|tr = 'Yuvarlama'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureTableRoundingRule()
	
	If PriceRoundingRules.Count() > 1 Then
		ConfigureTableRoundingRuleServer(ThisForm);
	Else
		
		If PriceRoundingRules.Count() = 1 Then
			
			If PriceRoundingRules[0].LowerBoundOfPriceRange = 0 Then
				PriceRange = NStr("vi = 'Tất cả đơn giá';
									|ru = 'Все цены';
									|en = 'All prices'; fa = 'همه قیمت‌ها';
									|it = 'Tutti i prezzi';
									|pl = 'Wszystkie ceny';
									|tr = 'Tüm fiyatlar'");
			Else
				
				PriceRange = NStr("vi = 'Cao hơn %StartOfRange_%';
									|ru = 'Свыше %StartOfRange_%';
									|en = 'More than %StartOfRange_%'; fa = 'More than %StartOfRange_%';
									|it = 'Superiore a %StartOfRange_%';
									|pl = 'Ponad %StartOfRange_%';
									|tr = '%StartOfRange_% üstü'");
				PriceRange = StrReplace(PriceRange, "%StartOfRange_%", PriceRoundingRules[0].LowerBoundOfPriceRange);
				
				If ValueIsFilled(PriceCurrency) Then
					PriceRange = PriceRange + " " + PriceCurrency;
				EndIf;
				
			EndIf;
			
			PriceRoundingRules[0].PriceRange = PriceRange;
			
			SetExample(ThisForm, 0);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureTableRoundingRuleServer(Form)
	
	If Form.PriceRoundingRules.Count() > 0 Then
		Form.PriceRoundingRules.Sort("LowerBoundOfPriceRange");
	EndIf;
	
	MaxIndex = Form.PriceRoundingRules.Count() - 1;
	For IndexOf = 0 To MaxIndex Do
		
		If Form.PriceRoundingRules.Count() = 1 And Form.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange = 0 Then
			PriceRange = NStr("vi = 'Tất cả đơn giá';
								|ru = 'Все цены';
								|en = 'All prices'; fa = 'همه قیمت‌ها';
								|it = 'Tutti i prezzi';
								|pl = 'Wszystkie ceny';
								|tr = 'Tüm fiyatlar'");
		Else
			
			If IndexOf = MaxIndex Then
				
				PriceRange = NStr("vi = 'Cao hơn %StartOfRange_%';
									|ru = 'Свыше %StartOfRange_%';
									|en = 'More than %StartOfRange_%'; fa = 'More than %StartOfRange_%';
									|it = 'Superiore a %StartOfRange_%';
									|pl = 'Ponad %StartOfRange_%';
									|tr = '%StartOfRange_% üstü'");
				PriceRange = StrReplace(PriceRange, "%StartOfRange_%", Form.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange);
				
			Else
				
				PriceRange = NStr("vi = 'Từ %StartOfRange_% đến %EndingOfRange%';
									|ru = 'От %StartOfRange_% до %EndingOfRange%';
									|en = 'From %StartOfRange_% to %EndingOfRange%'; fa = 'From %StartOfRange_% to %EndingOfRange%';
									|it = 'Da %StartOfRange_% a %EndingOfRange%';
									|pl = 'Od %StartOfRange_% do %EndingOfRange%';
									|tr = 'Başlangıcı %StartOfRange_% bitişi %EndingOfRange%'");
				PriceRange = StrReplace(PriceRange, "%StartOfRange_%",    Form.PriceRoundingRules[IndexOf].LowerBoundOfPriceRange);
				PriceRange = StrReplace(PriceRange, "%EndingOfRange%", Form.PriceRoundingRules[IndexOf + 1].LowerBoundOfPriceRange);
				
			EndIf;
			
			If ValueIsFilled(Form.PriceCurrency) Then
				PriceRange = PriceRange + " " + Form.PriceCurrency;
			EndIf;
			
		EndIf;
		
		Form.PriceRoundingRules[IndexOf].PriceRange = PriceRange;
		
		SetExample(Form, IndexOf);
		
	EndDo;
	
EndProcedure

&AtClient
Function GetParametersOfPriceEditingForm(Formula)
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Formula", Formula);
	ReturnStructure.Insert("OperandsTree", AddressOfTheStorageOfBasicTypesOfPrices);
	ReturnStructure.Insert("OperandsTitle", NStr("vi = 'Dạng giá được phép';
												|ru = 'Доступные виды цен';
												|en = 'Available price types'; fa = 'Available price types';
												|it = 'Tipi di prezzi disponibili';
												|pl = 'Dostępne rodzaje cen';
												|tr = 'Mevcut fiyat türleri'"));
	ReturnStructure.Insert("Operators", OperatorsTreeStorageAddress);
	ReturnStructure.Insert("ResultType", New TypeDescription("Number"));

	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure CustomizeForm()
	
	AdjustVisibilityAccessibilityHeader();
	
	// Forming a selection list for the Rounding Rule field The Rounding value
	Items.PriceRoundingRulesRoundingPrecision.ChoiceList.Clear();
	RoundingValue             = 0.01;
	EvenIncrement               = False;
	MaximumRoundingValue = 1000;
	PriceRangeBoundary            = -1;
	
	While RoundingValue <= MaximumRoundingValue 
		And (RoundingValue <= PriceRangeBoundary Or PriceRangeBoundary < 0) Do
		
		Items.PriceRoundingRulesRoundingPrecision.ChoiceList.Add(RoundingValue);
		RoundingValue = RoundingValue * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
EndProcedure


#EndRegion