
#Region FormHeaderItemsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ImportOldPrices   = Parameters.ImportOldPrices;
	RoundingUpManualPrices = Parameters.RoundingUpManualPrices;
	CalculationByFormulas    = Parameters.CalculationByFormulas;
	
	DownloadPriceTypes();
	
	SelectedLinesOnly = Parameters.OnlySelectedItems;
	OnlyEmpty    = 0;
	OldPriceDate          = Parameters.DocumentDate;
	ApplyRounding    = True;
	
	Items.OK.Title                                = ?(ImportOldPrices, NStr("vi = 'Kết nhập';
																			|ru = 'Загрузить';
																			|en = 'Import'; fa = 'ورود اطلاعات';
																			|it = 'Scaricare';
																			|pl = 'Import';
																			|tr = 'İçe aktar'"), ?(RoundingUpManualPrices, NStr("vi = 'Làm tròn';
																															|ru = 'Округлить';
																															|en = 'Round off'; fa = 'گرد کردن';
																															|it = 'Arrotondare';
																															|pl = 'Round off';
																															|tr = 'Yuvarla'"), NStr("vi = 'Tính toán';
																																						|ru = 'Рассчитать';
																																						|en = 'Calculate'; fa = 'محاسبه';
																																						|it = 'Calcolare';
																																						|pl = 'Calculate';
																																						|tr = 'Hesapla'")));
	Items.TypesOfPricesShouldRecalculate.Title                = ?(ImportOldPrices, NStr("vi = 'Kết nhập';
																						|ru = 'Загрузить';
																						|en = 'Import'; fa = 'ورود اطلاعات';
																						|it = 'Scaricare';
																						|pl = 'Import';
																						|tr = 'İçe aktar'"), ?(RoundingUpManualPrices, NStr("vi = 'Làm tròn';
																																		|ru = 'Округлить';
																																		|en = 'Round off'; fa = 'گرد کردن';
																																		|it = 'Arrotondare';
																																		|pl = 'Round off';
																																		|tr = 'Yuvarla'"), NStr("vi = 'Cập nhật lại';
																																									|ru = 'Пересчитать';
																																									|en = 'Recalculate'; fa = 'محاسبه مجدد';
																																									|it = 'Ricalcolare';
																																									|pl = 'Recalculate';
																																									|tr = 'Yeniden hesapla'")));
	Items.SelectedLinesOnly.Title            = ?(RoundingUpManualPrices, NStr("vi = 'Làm tròn các dòng trong chứng từ';
																				|ru = 'Округлить строки документа';
																				|en = 'Round document lines'; fa = 'Round document lines';
																				|it = 'Arrotondare le righe del documento';
																				|pl = 'Zaokrąglij wiersze dokumentu';
																				|tr = 'Belge satırlarını yuvarla'"), NStr("vi = 'Cập nhật lại các dòng trong chứng từ';
																													|ru = 'Пересчитать строки документа';
																													|en = 'Recalculate document lines'; fa = 'محاسبه مجدد سطرهای سند';
																													|it = 'Ricalcola le stringhe del documento';
																													|pl = 'Przelicz wiersze dokumentu';
																													|tr = 'Belge satırlarını yeniden hesapla'"));
	Items.OldPriceConversionParametersGroup.Visible = ImportOldPrices;
	Items.LabelRoundingUp.Visible                 = RoundingUpManualPrices;
	Items.TypesOfPricesPricingMethod.Visible          = Not ImportOldPrices And Not RoundingUpManualPrices;
	Items.OnlyEmpty.Visible               = Not RoundingUpManualPrices;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure TypesOfPricesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Item.CurrentData <> Undefined Then
		ShowValue(Undefined, Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ArrayOfPriceTypes = New Array();
	
	For Each PriceKind In TypesOfPrices Do
		
		If PriceKind.ShouldRecalculate Then
			If CalculationByFormulas Then
				ArrayOfPriceTypes.Add(New Structure("PriceKind, Formula", PriceKind.Ref, ""));
			Else
				ArrayOfPriceTypes.Add(PriceKind.Ref);
			EndIf;
		EndIf;
		
	EndDo;
	
	Result = New Structure();
	Result.Insert("ImportOldPrices",      ImportOldPrices);
	Result.Insert("RoundingUpManualPrices",    RoundingUpManualPrices);
	Result.Insert("TypesOfPrices",                ArrayOfPriceTypes);
	Result.Insert("SelectedLinesOnly", SelectedLinesOnly = 1);
	Result.Insert("OnlyEmpty",    OnlyEmpty = 1);
	Result.Insert("CalculationByFormulas",       CalculationByFormulas);
	
	If ImportOldPrices Then
		
		Result.Insert("OldPriceDate",        EndOfDay(OldPriceDate));
		Result.Insert("PriceChangePercentage", PriceChangePercentage);
		Result.Insert("ApplyRounding",  ApplyRounding);
		
	EndIf;
	
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

#Region Other

// The procedure loads the price types in the price Types table in the order
// that corresponds to the order in the document.
&AtServer
Procedure DownloadPriceTypes()
	
	Query = New Query();
	Query.Text = "SELECT
	|	TypesOfPrices.Ref AS Ref,
	|	TypesOfPrices.PricingMethod AS PricingMethod,
	|	CASE
	|		WHEN TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.Manually)
	|			THEN 0
	|		WHEN TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.FillInByInfobaseData)
	|			THEN 1
	|		WHEN TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes)
	|			THEN 2
	|	END AS PictureIndex
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Ref IN (&ArrayOfPriceTypes)";
	
	Query.SetParameter("ArrayOfPriceTypes", Parameters.ManualPriceViews);
	TableOfPriceTypes = Query.Execute().Unload();
	
	// In order for the types of prices in the list to be in the same order as on the document form,
	// we load them manually.
	For Each PriceKind In Parameters.ManualPriceViews Do
		
		FoundTypeOfPrices = TableOfPriceTypes.Find(PriceKind, "Ref");
		
		PriceViewString                   = TypesOfPrices.Add();
		PriceViewString.Ref            = PriceKind;
		PriceViewString.PricingMethod = FoundTypeOfPrices.PricingMethod;
		PriceViewString.ShouldRecalculate       = True;
		PriceViewString.PictureIndex    = FoundTypeOfPrices.PictureIndex;
		
	EndDo;
	
EndProcedure

#EndRegion

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
