
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters.DetailsForFillIn, , "Periodicity");
	Periodicity = Common.ObjectAttributeValue(Owner, "Periodicity");
	ForecastByWeek = (Periodicity = Enums.Periodicity.Week);
	
	If PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
		TextPredictionOptionsByCategory = NStr("vi = 'Phương án đã chọn xác định, sẽ hiển thị dữ liệu dự báo để phân tích theo dạng nào:
			| %1 Chỉ theo thể loại   - dữ liệu được hiển thị theo thể loại.
			| %1 Có chia nhỏ theo hàng hóa - dữ liệu được hiển thị theo hàng hóa.';
			|ru = 'Выбранный вариант определяет, в каком виде данные прогнозов будут выводиться для анализа:
			| %1 Только по категориям   - данные выводятся по категориям.
			| %1 С разбивкой по товарам - данные выводятся по товарам.';
			|en = 'The selected option identifies how the forecast data will be displayed for analysis:
			| %1 Only by category. Data is displayed by category.
			| %1 Broken down by items. Data is displayed by item.'; fa = 'The selected option identifies how the forecast data will be displayed for analysis:
			| %1 Only by category. Data is displayed by category.
			| %1 Broken down by items. Data is displayed by item.';
			|it = 'Выбранный вариант определяет, в каком виде данные прогнозов будут выводиться для анализа:
			| %1 Только по категориям   - данные выводятся по категориям.
			| %1 С разбивкой по товарам - данные выводятся по товарам.';
			|pl = 'The selected option identifies how the forecast data will be displayed for analysis:
			| %1 Only by category. Data is displayed by category.
			| %1 Broken down by items. Data is displayed by item.';
			|tr = 'Seçilen seçenek, tahmin verilerinin analiz için hangi biçimde görüntüleneceğini tanımlamaktadır:
			| %1Sadece kategoriye göre; veriler kategoriye göre görüntülenir.
			| %1Ürünlere göre ayrılmış; veriler ürünlere göre görüntülenir.'");
		TextPredictionOptionsByCategory = StrTemplate(TextPredictionOptionsByCategory, Char(8226));
		Items.DecorationIsVariantOfForecastingByCategory.ToolTip = TextPredictionOptionsByCategory;
	EndIf;
	
	RecalculateDataDependentOnStartOfPrediction(False);
	SetVisibilityAvailability();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ForecastingStartOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ClearMessages();
	RecalculateDataDependentOnStartOfPrediction();
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure DayOfTheWeekOfTheForecastStartOnChange(Item)
	
	ClearMessages();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibilityAvailability()
	
	Items.DayOfTheWeekOfTheForecastStart.Visible = ForecastByWeek;
	Items.InscriptionGroupHasSetDatesForBanningChanges.Visible = ThereIsBanOnChangingData;
	Items.GroupForecastingOptionByCategory.Visible = PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	
EndProcedure

&AtServer
Procedure RecalculateDataDependentOnStartOfPrediction(CheckDayOfWeek = True)
	
	
	DataToCheck  = PeriodClosingDates.DataToCheckTemplate();
	
	NewRow        = DataToCheck.Add();
	NewRow.Date   = BegOfDay(ForecastingStart);
	NewRow.Section = "Planning";
	NewRow.Object = Owner;
	
	DataDetails = New Structure("NewVersion, Data", False, "");
	
	ThereIsBanOnChangingData = False;
	ErrorDescription = "";
	If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, DataDetails, ErrorDescription) Then
		ThereIsBanOnChangingData = True;
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
	If Item.Name = "sh_ShamsiInput_F_ForecastingStart" Then
		ForecastingStartOnChange(Items.ForecastingStart);
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
