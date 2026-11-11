#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	// Show
	ValidPriceDate                         = Parameters.ValidPriceDate;
	ShowPriceChange                    = Parameters.ShowPriceChange;
	ShowMarkupPercent                   = Parameters.ShowMarkupPercent;
	ShowEffectivePrices                  = Parameters.ShowEffectivePrices;
	ShowTheQuickEditToolbarCheckbox = Parameters.Property("ShowTheQuickEditPanel", ShowTheQuickEditPanel);
	TheShowCheckBoxToShowFormulas          = Parameters.Property("ShowFormulas", ShowFormulas);
	ShowTheShowCurrencyCheckbox           = Parameters.Property("ShowCurrency", ShowCurrency);
	TheShowCheckBoxToShowUnitsOfMeasurement = Parameters.Property("ShowUnitsOfMeasurement", ShowUnitsOfMeasurement);
	ShowShowVATRateCheckbox        = Parameters.Property("ShowVATRate", ShowVATRate);
	
	// Parameters
	ShowCountCheckBoxToAutomatically  = Parameters.Property("CalculateAutomatically", CalculateAutomatically);
	TheShowCheckBoxToDisplayAffectPrices     = Parameters.Property("ShowInfluencingPrices", ShowInfluencingPrices);
	TheShowCheckBoxToUseASingleColumnForTheKeyPrices = Parameters.Property("UseOneColumnForThePriceKey", UseOneColumnForThePriceKey);
	TheShowCheckBoxToLockTheColumnOfTheItem   = Parameters.Property("FixTheItemColumn", FixTheItemColumn);
	
	SetFormItemEnabled(ThisForm);
	
	If Not Parameters.ShowDate Then
		Items.ShowOldPrices.Title = NStr("vi = 'Hiển thị đơn giá hiện tại';
										|ru = 'Показывать действующие цены';
										|en = 'Show effective prices'; fa = 'نمایش قیمت‌های مؤثر';
										|it = 'Mostrare i prezzi pertinenti';
										|pl = 'Pokazuj obowiązujące ceny';
										|tr = 'Geçerli fiyatları göster'");
		Items.ValidPriceDate.Visible = False;
	EndIf;
	
	Items.ShowTheQuickEditPanel.Visible 	= ShowTheQuickEditToolbarCheckbox;
	Items.ShowFormulas.Visible 						= TheShowCheckBoxToShowFormulas;
	Items.ShowCurrency.Visible 						= ShowTheShowCurrencyCheckbox;
	Items.ShowUnitsOfMeasurement.Visible 				= TheShowCheckBoxToShowUnitsOfMeasurement;
	Items.CalculateAutomatically.Visible 				= ShowCountCheckBoxToAutomatically;
	Items.ShowInfluencingPrices.Visible 					= TheShowCheckBoxToDisplayAffectPrices;
	Items.UseOneColumnForThePriceKey.Visible 		= TheShowCheckBoxToUseASingleColumnForTheKeyPrices;
	Items.FixTheItemColumn.Visible 		= TheShowCheckBoxToLockTheColumnOfTheItem;
	Items.ShowVATRate.Visible 						= ShowShowVATRateCheckbox;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)

	ReturnStructure = New Structure();
	ReturnStructure.Insert("ShowPriceChange",   				ShowPriceChange);
	ReturnStructure.Insert("ShowMarkupPercent",  				ShowMarkupPercent);
	ReturnStructure.Insert("ShowEffectivePrices", 				ShowEffectivePrices);
	ReturnStructure.Insert("ValidPriceDate",        				ValidPriceDate);
	ReturnStructure.Insert("ShowTheQuickEditPanel",	ShowTheQuickEditPanel);		
	
	ReturnStructure.Insert("ShowFormulas",							ShowFormulas);
	ReturnStructure.Insert("ShowCurrency",							ShowCurrency);
	ReturnStructure.Insert("ShowUnitsOfMeasurement",				ShowUnitsOfMeasurement);
	ReturnStructure.Insert("ShowVATRate",						ShowVATRate);

	ReturnStructure.Insert("CalculateAutomatically",					CalculateAutomatically);
	ReturnStructure.Insert("ShowInfluencingPrices",					ShowInfluencingPrices);
	ReturnStructure.Insert("UseOneColumnForThePriceKey",		UseOneColumnForThePriceKey);
	ReturnStructure.Insert("FixTheItemColumn",			FixTheItemColumn);

	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure ShowOldPricesOnChange(Item)
	
	UpdateValuesOfRelatedProps();
	SetFormItemEnabled(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetFormItemEnabled(Form)
	
	Form.Items.ValidPriceDate.Enabled       = Form.ShowEffectivePrices;
	Form.Items.ShowPriceChange.Enabled  = Form.ShowEffectivePrices;
	Form.Items.ShowMarkupPercent.Enabled = Form.ShowEffectivePrices;
	
EndProcedure

&AtClient
Procedure UpdateValuesOfRelatedProps()
	
	If Not ShowEffectivePrices Then
		ShowPriceChange = False;
		ShowMarkupPercent = False;
		ValidPriceDate = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
