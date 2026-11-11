 
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetConditionalAppearance();

	DownloadPriceTypes();
	
	SelectedLinesOnly = Parameters.OnlySelectedItems;
	ApplyRounding    = True;
	
	Items.SelectedLinesOnly.Title = NStr("vi = 'Cập nhật lại các dòng trong chứng từ';
										|ru = 'Пересчитать строки документа';
										|en = 'Recalculate document lines'; fa = 'محاسبه مجدد سطرهای سند';
										|it = 'Ricalcola le stringhe del documento';
										|pl = 'Przelicz wiersze dokumentu';
										|tr = 'Belge satırlarını yeniden hesapla'");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	OptionToChangeThePrice	= 1;
	
	ConfigureVisibilityAndAccessibilityOfFormElements(ThisForm)
	
EndProcedure

&AtClient
Procedure OptionToChangeThePriceOnChange(Item)
	
	ConfigureLineSelection(ThisForm);
	ConfigureVisibilityAndAccessibilityOfFormElements(ThisForm);
	
EndProcedure

&AtServerNoContext
Function AllowChangingFormulas(PricingMethod)
	
	Return  Catalogs.TypesOfPrices.AllowChangingFormulas(PricingMethod); 
	
EndFunction


&AtClient
Procedure ConfigureLineSelection(Form)
		
	RowFilter = New FixedStructure("DisplayAString", True);	
	
	If Form.OptionToChangeThePrice=1 Then //change to a percentage
		
		For Each Page1 In TypesOfPrices Do
			Page1.DisplayAString = Page1.ExpandByCurrency;
			If Not Page1.ExpandByCurrency Then 
				Page1.ShouldRecalculate = False;
			EndIf;
		EndDo;
		Form.Items.TypesOfPrices.RowFilter = RowFilter;
		
	ElsIf Form.OptionToChangeThePrice=2 Then  //change to value
		
		For Each Page1 In TypesOfPrices Do
			Page1.DisplayAString = True;
		EndDo;

		Form.Items.TypesOfPrices.RowFilter = Undefined;	
		
	ElsIf Form.OptionToChangeThePrice=3 Then //set value
		
		For Each Page1 In TypesOfPrices Do
			Page1.DisplayAString = True;
		EndDo;
		
		Form.Items.TypesOfPrices.RowFilter = Undefined;
		
	ElsIf Form.OptionToChangeThePrice=4 Then //RoundOff
		
		For Each Page1 In TypesOfPrices Do
			If Page1.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.Manually")
				And Page1.ExpandByCurrency Then
				Page1.DisplayAString = True;
				Page1.ShouldRecalculate = False;
			Else
				Page1.DisplayAString = False;
			EndIf;		
		EndDo;
		Form.Items.TypesOfPrices.RowFilter = RowFilter;
		
	ElsIf Form.OptionToChangeThePrice=5 Then //calculate by the formula
		
		For Each Page1 In TypesOfPrices Do
			If AllowChangingFormulas(Page1.PricingMethod) Then
				Page1.DisplayAString = Page1.ExpandByCurrency;
				Page1.ShouldRecalculate = False;
			Else
				Page1.DisplayAString = False;
			EndIf;
		EndDo;
		Form.Items.TypesOfPrices.RowFilter = RowFilter;
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureVisibilityAndAccessibilityOfFormElements(Form)

	Form.Items.OK.Title 				= NStr("vi = 'Thay đổi';
												|ru = 'Изменить';
												|en = 'Change'; fa = 'تغییر';
												|it = 'Modificare';
												|pl = 'Change';
												|tr = 'Değiştir'");
	
	Form.Items.ChangeOption.Visible 	= True;
	Form.Items.ApplyRounding.Visible= True;
	Form.Items.LabelRoundingUp.Visible	= False;
	RowFilter = New FixedStructure("DisplayAString", True);
	
	If Form.OptionToChangeThePrice=1 Then
		
		Form.Items.ChangeOption.Title 		= NStr("vi = 'Thay đổi phần trăm so với';
													|ru = 'Изменять на процент по отношению к';
													|en = 'Change on percentage in relation to'; fa = 'تغییر بر اساس درصد نسبت به';
													|it = 'Modifica con applicazione della percentuale in relazione a';
													|pl = 'Zmień na procent w stosunku do';
													|tr = 'Yüzde olarak değiştirileceği'");
		Form.Title 								= NStr("vi = 'Thay đổi theo phần trăm';
															|ru = 'Изменить на процент';
															|en = 'Change by percentage'; fa = 'تغییر بر اساس درصد';
															|it = 'Cambia in percentuale';
															|pl = 'Zmień na procent';
															|tr = 'Yüzde olarak değiştir'");
			
		Form.Items.TypesOfPricesChangePercentage.Visible= True;
		Form.Items.TypesOfPricesAmountOfChange.Visible 	= False;
		Form.Items.TypesOfPricesPrice.Visible 			= False;
		Form.Items.TypesOfPricesRefPriceCurrency.Visible= False;
		Form.Items.TypesOfPricesFormula.Visible= False;
		Form.Items.TypesOfPrices.RowFilter = RowFilter;
		
	ElsIf Form.OptionToChangeThePrice=2 Then
			
		Form.Items.ChangeOption.Title 		= NStr("vi = 'Thay đổi số tiền so với';
													|ru = 'Изменять на сумму по отношению к';
													|en = 'Change by amount in relation to'; fa = 'Change by amount in relation to';
													|it = 'Modificare nell''importo relativamente a';
													|pl = 'Zmieniaj o wartość w stosunku do';
													|tr = 'Tutar olarak değiştirileceği'");
		Form.Title 								= NStr("vi = 'Thay đổi số tiền';
															|ru = 'Изменить на сумму';
															|en = 'Change by amount'; fa = 'تغییر بر اساس مبلغ';
															|it = 'Modificare nell''importo';
															|pl = 'Zmień o wartość';
															|tr = 'Tutar olarak değiştir'");
			
		Form.Items.TypesOfPricesChangePercentage.Visible= False;
		Form.Items.TypesOfPricesAmountOfChange.Visible 	= True;
		Form.Items.TypesOfPricesPrice.Visible 			= False;
		Form.Items.TypesOfPricesRefPriceCurrency.Visible= True;
		Form.Items.TypesOfPricesFormula.Visible= False;
				
	ElsIf Form.OptionToChangeThePrice=3 Then

		Form.Title 								= NStr("vi = 'Đặt bảng giá';
															|ru = 'Установить цену';
															|en = 'Set price'; fa = 'تعیین قیمت';
															|it = 'Impostare prezzo';
															|pl = 'Ustaw cenę';
															|tr = 'Fiyat belirle'");
			
		Form.Items.ChangeOption.Visible 		= False;
		Form.Items.ApplyRounding.Visible	= False;
		Form.Items.OK.Title 					= NStr("vi = 'Áp dụng';
														|ru = 'Применить';
														|en = 'Apply'; fa = 'اعمال';
														|it = 'Applica ';
														|pl = 'Apply';
														|tr = 'Uygula'");
		
		Form.Items.TypesOfPricesChangePercentage.Visible= False;
		Form.Items.TypesOfPricesAmountOfChange.Visible 	= False;
		Form.Items.TypesOfPricesPrice.Visible 			= True;
		Form.Items.TypesOfPricesRefPriceCurrency.Visible= True;
		Form.Items.TypesOfPricesFormula.Visible= False;
		
	ElsIf Form.OptionToChangeThePrice=4 Then
		
		Form.Title 								= NStr("vi = 'Làm tròn đơn giá';
															|ru = 'Округлить цены';
															|en = 'Round prices'; fa = 'Round prices';
															|it = 'Arrotondare prezzo';
															|pl = 'Zaokrąglaj ceny';
															|tr = 'Fiyatları yuvarla'");
		
		Form.Items.LabelRoundingUp.Visible		= True;
			
		Form.Items.ChangeOption.Visible 		= False;
		Form.Items.ApplyRounding.Visible	= False;
		Form.Items.OK.Title 					= NStr("vi = 'Làm tròn';
														|ru = 'Округлить';
														|en = 'Round off'; fa = 'گرد کردن';
														|it = 'Arrotondare';
														|pl = 'Round off';
														|tr = 'Yuvarla'");
		
		Form.Items.TypesOfPricesChangePercentage.Visible= False;
		Form.Items.TypesOfPricesAmountOfChange.Visible 	= False;
		Form.Items.TypesOfPricesPrice.Visible 			= False;
		Form.Items.TypesOfPricesRefPriceCurrency.Visible= False;
		Form.Items.TypesOfPricesFormula.Visible= False;
	
	ElsIf Form.OptionToChangeThePrice=5 Then
			
		Form.Title 								= NStr("vi = 'Tính theo công thức';
															|ru = 'Рассчитать по формуле';
															|en = 'Calculate using formula'; fa = 'محاسبه با فرمول';
															|it = 'Calcolar ein base alla formula';
															|pl = 'Oblicz wg formuły';
															|tr = 'Formüle göre hesapla'");
		
		Form.Items.ChangeOption.Visible 		= False;
		Form.Items.ApplyRounding.Visible	= False;
		Form.Items.OK.Title 					= NStr("vi = 'Tính toán';
														|ru = 'Рассчитать';
														|en = 'Calculate'; fa = 'محاسبه';
														|it = 'Calcolare';
														|pl = 'Calculate';
														|tr = 'Hesapla'");
		
		Form.Items.TypesOfPricesChangePercentage.Visible= False;
		Form.Items.TypesOfPricesAmountOfChange.Visible 	= False;
		Form.Items.TypesOfPricesPrice.Visible 			= False;
		Form.Items.TypesOfPricesRefPriceCurrency.Visible= False;
		Form.Items.TypesOfPricesFormula.Visible= True;
	EndIf;
	
EndProcedure

&AtServer
Function GetParametersOfPriceEditingForm(TagName,Formula, PriceKind)
	
	InfluencingPrices = GetTableOfInfluencingPrices(PriceKind);
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Formula", Formula);
	ReturnStructure.Insert("OperandsTree", PutInfluencingKindsOfPricesInStorage(InfluencingPrices));
	ReturnStructure.Insert("OperandsTitle", NStr("vi = 'Dạng giá được phép';
												|ru = 'Доступные виды цен';
												|en = 'Available price types'; fa = 'Available price types';
												|it = 'Tipi di prezzi disponibili';
												|pl = 'Dostępne rodzaje cen';
												|tr = 'Mevcut fiyat türleri'"));
	ReturnStructure.Insert("Operators", OperatorsTreeStorageAddress);
	ReturnStructure.Insert("ResultType", New TypeDescription("Number"));
	ReturnStructure.Insert("ThisIsPriceCalculation", True);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure TypesOfPricesFormulaStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.TypesOfPrices.CurrentData;
	AdditionalParameters = New Structure("NameOfReturnElement", "Formula");
	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersOfPriceEditingForm(Item.Name, CurrentData["Formula"], CurrentData["Ref"]),
		 Item,,,, New CallbackDescription("FormulasConstructorCompletion", ThisObject,AdditionalParameters),
		 FormWindowOpeningMode.LockWholeInterface);
		
EndProcedure

&AtClient
Procedure FormulasConstructorCompletion(Result, AdditionalParameters) Export
	
	EditResult = Result;
	CurrentData = Items.TypesOfPrices.CurrentData;
	
	If EditResult <> Undefined Then
		CurrentData[AdditionalParameters.NameOfReturnElement]	= EditResult;	
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypesOfPrices

&AtClient
Procedure TypesOfPricesChangePercentageOnChange(Item)
	
	CurrentData = Items.TypesOfPrices.CurrentData;
	CurrentData.ShouldRecalculate = True;
	
EndProcedure


&AtClient
Procedure TypesOfPricesAmountOfChangeOnChange(Item)
	
	CurrentData = Items.TypesOfPrices.CurrentData;
	CurrentData.ShouldRecalculate = True;

EndProcedure

&AtClient
Procedure TypesOfPricesPriceOnChange(Item)
	
	CurrentData = Items.TypesOfPrices.CurrentData;
	CurrentData.ShouldRecalculate = True;

EndProcedure

&AtClient
Procedure TypesOfPricesFormulaOnChange(Item)
	
	CurrentData = Items.TypesOfPrices.CurrentData;
	CurrentData.ShouldRecalculate = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
		
	ArrayOfPriceTypes = New Array();
	For Each PriceKind In TypesOfPrices Do
		If PriceKind.ShouldRecalculate Then
			If OptionToChangeThePrice = 1 Then // change to a percentage
				ArrayOfPriceTypes.Add(New Structure("PriceKind, ChangePercentage", PriceKind.Ref, PriceKind.ChangePercentage));
			ElsIf OptionToChangeThePrice = 2 Then // change by amount
				ArrayOfPriceTypes.Add(New Structure("PriceKind, AmountOfChange, PriceCurrency", PriceKind.Ref, 
																							   PriceKind.AmountOfChange, 
																							   PriceKind.PriceCurrency));
			ElsIf OptionToChangeThePrice = 3 Then // set the price
				ArrayOfPriceTypes.Add(New Structure("PriceKind, Price, PriceCurrency", PriceKind.Ref, 
																					 PriceKind.Price, 
																					 PriceKind.PriceCurrency));
			ElsIf OptionToChangeThePrice = 4 Then // RoundOff
				ArrayOfPriceTypes.Add(PriceKind.Ref);
			ElsIf OptionToChangeThePrice = 5 Then // according to the formula
				ArrayOfPriceTypes.Add(New Structure("PriceKind, Formula", PriceKind.Ref, PriceKind.Formula));
				ApplyRounding = False;
			EndIf;
		EndIf;
	EndDo;
	
	Result = New Structure();
	Result.Insert("ChangeInRelationToOldPrice", ChangeOption = 1);
	Result.Insert("TypesOfPrices",                        ArrayOfPriceTypes);
	Result.Insert("SelectedLinesOnly",         SelectedLinesOnly = 1);
	Result.Insert("ApplyRounding",            ApplyRounding);
	Result.Insert("OptionToChangeThePrice",           OptionToChangeThePrice);
	Result.Insert("ImportOldPrices",              ImportOldPrices);
	Result.Insert("RoundingUpManualPrices",            ApplyRounding);
	Result.Insert("OnlyEmpty",            False);
	Result.Insert("CalculationByFormulas",               OptionToChangeThePrice = 5);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure PriceTypesSelectAll(Command)
	
	For Each PriceKind In TypesOfPrices Do
		If Not PriceKind.ShouldRecalculate Then
			PriceKind.ShouldRecalculate = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure PriceTypesExcludeAll(Command)
	
	For Each PriceKind In TypesOfPrices Do
		If PriceKind.ShouldRecalculate Then
			PriceKind.ShouldRecalculate = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TypesOfPricesFormula.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TypesOfPrices.Formula");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<công thức mặc định đối với dạng giá>';
													|ru = '<формула по умолчанию для вида цен>';
													|en = '<default formula for price type>'; fa = '<default formula for price type>';
													|it = '<формула по умолчанию для вида цен>';
													|pl = '<default formula for price type>';
													|tr = '<fiyat türü için varsayılan formül>'"));

EndProcedure

#Region Other

&AtServer
Function GetTableFromArrayOfRows(RowsArray)
	
	ValueTable = New ValueTable();
	ValueTable.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	ValueTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	For Each Page1 In RowsArray Do
		RowNew_ = ValueTable.Add();
		FillPropertyValues(RowNew_, Page1);
	EndDo;
	
	Return ValueTable; 
	
EndFunction

// The procedure loads the price types in the price Types table in the order
// that corresponds to the order in the document.
&AtServer
Procedure DownloadPriceTypes()
	
	Query = New Query();
		
	If Parameters.Property("ArrayOfCurrenciesByPriceType") Then

		Query.Text = "
		|SELECT 
		|	PriceKind AS PriceKind,
		|   Currency AS Currency
		|INTO CurrencyTable
		|FROM
		|&TableOfCurrenciesByTypeOfPrices AS TableOfCurrenciesByTypeOfPrices
		|;
		|SELECT
		|	TypesOfPrices.Ref            AS Ref,
		|	CurrencyTable.Currency       AS PriceCurrency,
		|	TypesOfPrices.PricingMethod AS PricingMethod,
		|	TypesOfPrices.Id AS Id,
		|	CASE
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.Manually)
		|		THEN
		|			0
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.FillInByInfobaseData)
		|		THEN
		|			1
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes)
		|		THEN
		|			2
		|	END AS PictureIndex
		|FROM
		|	CurrencyTable
		|	LEFT JOIN
		|		Catalog.TypesOfPrices AS TypesOfPrices
		|		ON (CurrencyTable.PriceKind = TypesOfPrices.Ref)
		|	WHERE
		|	TypesOfPrices.Ref IS NOT NULL";
		
		
		TableOfCurrenciesByTypeOfPrices = GetTableFromArrayOfRows(Parameters.ArrayOfCurrenciesByPriceType);
		Query.SetParameter("TableOfCurrenciesByTypeOfPrices", TableOfCurrenciesByTypeOfPrices);	
		
	Else
		Query.Text = "SELECT
		|	TypesOfPrices.Ref            AS Ref,
		|	TypesOfPrices.PriceCurrency        AS PriceCurrency,
		|	TypesOfPrices.PricingMethod AS PricingMethod,
		|	TypesOfPrices.Id AS Id,
		|	CASE
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.Manually)
		|		THEN
		|			0
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.FillInByInfobaseData)
		|		THEN
		|			1
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes)
		|		THEN
		|			2
		|	END AS PictureIndex
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.Ref IN(&ArrayOfPriceTypes)";

		Query.SetParameter("ArrayOfPriceTypes", Parameters.AllKindsOfPrices);
		
	EndIf;	
	TableOfPriceTypes = Query.Execute().Unload();
	
	// In order for the types of prices in the list to be in the same order as on the document form,
	// we load them manually
	For Each PricesKind In Parameters.AllKindsOfPrices Do
		
		Filter = New Structure();
		Filter.Insert("Ref", PricesKind); 
		FoundTypeOfPrices = TableOfPriceTypes.FindRows(Filter);	
		Indus = 0;
		For Each Page1 In FoundTypeOfPrices Do		

			PriceViewString                   = TypesOfPrices.Add();
			PriceViewString.Ref            = PricesKind;
			PriceViewString.PricingMethod = Page1.PricingMethod;
			PriceViewString.ShouldRecalculate       = False;
			PriceViewString.PictureIndex    = Page1.PictureIndex;
			PriceViewString.Id = Page1.Id;
			PriceViewString.PriceCurrency = Page1.PriceCurrency;
			If  Indus = 0 Then
				PriceViewString.DisplayAString = True;
				PriceViewString.ExpandByCurrency = True;
			Else
				PriceViewString.DisplayAString = False;
				PriceViewString.ExpandByCurrency = False;
				PriceViewString.ShouldRecalculate = False;
			EndIf;	
			
			Indus = Indus + 1;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetTableOfInfluencingPrices(PriceKind)
	
	Query = New Query();
	Query.Parameters.Insert("PriceKind",PriceKind);
	Query.Text = "SELECT DISTINCT
	|	TypesOfPricesInfluencingPriceTypes.InfluencingPriceType AS Ref,
	|	TypesOfPricesInfluencingPriceTypes.InfluencingPriceType.Id AS Id,
	|	TypesOfPricesInfluencingPriceTypes.InfluencingPriceType.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.TypesOfPrices.InfluencingPriceTypes AS TypesOfPricesInfluencingPriceTypes
	|WHERE
	|	TypesOfPricesInfluencingPriceTypes.Ref = &PriceKind";
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

&AtServer
Function PutInfluencingKindsOfPricesInStorage(InfluencingPrices)

	Tree = ProcessingOfFormulas.GetEmptyOperandTree();

	For Each LineTypesOfPrice In InfluencingPrices Do	
		OperandString_ = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
		OperandString_.Id = LineTypesOfPrice.Id;
		OperandString_.Presentation = String(LineTypesOfPrice.Ref);
		OperandString_.DeletionMark = LineTypesOfPrice.DeletionMark;
		OperandString_.ValueType = New TypeDescription("Number");
	EndDo;
	
	AddressInStorage = PutToTempStorage(Tree, UUID);
	
	Return AddressInStorage;
	
EndFunction

#EndRegion

#EndRegion
