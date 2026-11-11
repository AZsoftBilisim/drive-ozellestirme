////////////////////////////////////////////////////////////////////////////////
// The "Clientserver Provisioning" module contains auxiliary procedures
// and functions for interactive user work with the provision of needs.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a string value of the item type used in the software subsystem.
// 
// Parameters:
//  ItemsType - EnumRef.ItemsTypes
//
// Returns:
//  String
//
Function ItemTypeByLine(ItemsType) Export
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Then
		Return "OwnGoods";
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		Return "Tara";
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		Return "Work_5";
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		Return "OperationService";
	EndIf;
	
EndFunction

// It is intended to describe how to check whether fields are filled in before executing a command to
// fill in security in documents.
//
// Parameters:
//  TabularSectionName - String, Undefined - the name of the list in which the check is performed, if not specified, the list " Products"
//  Synonym - String, Undefined - the name of the list in which the check is performed, if not specified, then the list of "Products".
//
// Returns:
//  Structure - structure with fields:
//   * Fields - Structure - structure with fields:
//     ** Products - String - path to the "Item" field,
//     ** Characteristic - String - path to the "Characteristic" field,
//     ** Warehouse - String - path to the "Warehouse" field,
//     ** Count - String - the path to the "Quantity" field,
//     ** NumberOfPackages - String - path to the "Number of packages" field
//   * Texts - Structure - structure with fields:
//     ** Products - String - message template for error checking filling in the "Item" field,
//     ** Characteristic - String - message template for error checking filling in the "Characteristic" field,
//     ** Warehouse - String - message template for error checking filling in the "Warehouse" field,
//     ** Count - String - message template for error checking filling in the "Quantity" field,
//     ** NumberOfPackages - String - message template for error checking filling in the "Number of packages" field
//
Function InitializeFillVerificationParameters(TabularSectionName = Undefined, Synonym = Undefined) Export

	Fields = New Structure();
	Fields.Insert("Products",   "Object.Goods[%1].Products");
	Fields.Insert("Characteristic", "Object.Goods[%1].Characteristic");
	Fields.Insert("Warehouse",          "Object.Warehouse");
	Fields.Insert("Count",     "Object.Goods[%1].NumberOfPackages");
	Fields.Insert("NumberOfPackages", "Object.Goods[%1].NumberOfPackages");

	Texts = New Structure();
	Texts.Insert("Products",   NStr("vi = 'Chưa điền cột ""Mặt hàng"" tại dòng %1 trong danh sách ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Номенклатура"" в строке %1 списка ""Товары""';
									|en = 'Column ""Items"" in line %1 of the ""Goods"" list is not filled in'; fa = 'Column ""Items"" in line %1 of the ""Goods"" list is not filled in';
									|it = 'Colonna articolo non riempita nella riga %1 dell''elenco ""Articoli""';
									|pl = 'Nie wypełniono kolumny ""Номенклатура"" w wierszu %1 listy ""Товары""';
									|tr = '""Ürünler"" listesinin %1 satırında ""Öğe"" sütunu doldurulmadı'"));
	Texts.Insert("Characteristic", NStr("vi = 'Chưa điền cột ""Đặc tính"" tại dòng %1 trong danh sách ""Hàng hóa""';
										|ru = 'Не заполнена колонка ""Характеристика"" в строке %1 списка ""Товары""';
										|en = 'Column ""Variant"" in line %1 of the ""Goods"" list is not filled in'; fa = 'Column ""Variant"" in line %1 of the ""Goods"" list is not filled in';
										|it = 'Non è compilata la colonna ""Caratteristica"" nella riga %1 dell''elenco ""Merci"".';
										|pl = 'Nie wypełniono kolumny ""Характеристика"" w wierszu %1 listy ""Товары""';
										|tr = '""Ürünler"" listesinin %1 satırında ""Varyant"" sütunu doldurulmadı'"));
	Texts.Insert("Warehouse",          NStr("vi = 'Chưa điền trường ""Kho bãi""';
											|ru = 'Поле ""Склад"" не заполнено';
											|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
											|it = 'Il campo ""Magazzino"" non è compilato';
											|pl = 'Nie wypełniono pola ""Magazyn""';
											|tr = '""Ambar"" alanı doldurulmamış'"));
	Texts.Insert("Count",     NStr("vi = 'Chưa điền cột ""Số lượng"" tại dòng %1 trong danh sách ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Количество"" в строке %1 списка ""Товары""';
									|en = 'Column ""Quantity"" in line %1 of the ""Goods"" list is not filled in'; fa = 'Column ""Quantity"" in line %1 of the ""Goods"" list is not filled in';
									|it = 'Colonna ""Quantità"" non riempita nella riga %1dell''elenco ""Articoli""';
									|pl = 'Nie wypełniono kolumny ""Количество"" w wierszu %1 listy ""Товары""';
									|tr = '""Ürünler"" listesinin %1 satırındaki ""Miktar"" sütunu doldurulmadı'"));
	Texts.Insert("NumberOfPackages", NStr("vi = 'Tìm thấy số lượng bằng 0 khi chuyển đổi sang đơn vị lưu trữ trong dòng %1 của danh sách ""Hàng hóa""';
											|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %1 списка ""Товары""';
											|en = 'Zero quantity is detected when converted to storage unit in line %1 of the Item list'; fa = 'Zero quantity is detected when converted to storage unit in line %1 of the Item list';
											|it = 'Quantità zero rilevata in termini di unità di archiviazione nella riga %1 dell''elenco ""Articoli""';
											|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania w wierszu %1 listy ""Товары""';
											|tr = '""Ürünler"" listesinin %1 satırında depolama birimine dönüştürülürken sıfır miktar bulundu'"));

	If TabularSectionName <> Undefined Then

		For Each Field In Fields Do

			Fields[Field.Key]   = StrReplace(Fields[Field.Key],   "Goods", TabularSectionName);
			Texts[Field.Key] = StrReplace(Texts[Field.Key], "Goods", ?(Synonym <> Undefined, Synonym, TabularSectionName));

		EndDo;

	EndIf;

	Return New Structure("Fields, Texts", Fields, Texts);

EndFunction

// Creates a data structure containing the parameters of the join tables
//
// Returns:
//  Structure - a data structure containing parameters for joining tables.
//
Function TableJoinParameters() Export

	Result = New Structure();
	Result.Insert("UpdateRows",  True);
	Result.Insert("AddLines_",  False);
	Result.Insert("NewLines",      Undefined);
	Result.Insert("ModifiedRows", Undefined);
	Result.Insert("Defaults",        Undefined);
	Return Result;

EndFunction

#EndRegion

#Region Internal

// The use assignment key for the "Need Assurance" processing form that is opened for generating orders. 
// 
// Returns:
//  String - The Key To The Purpose Of Using The Formation Of Applications According To Needs
Function KeyToPurposeOfUsingFormationOfOrdersAccordingToNeeds() Export
	
	Return ""; // To use the default value
	
EndFunction

// The use assignment key is for the "Need Assurance" processing Form, which is opened for the formation of applications. 
// 
// Returns:
//  String - The Key To The Purpose Of Using The Formation Of Applications According To Needs
Function KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Export
	
	Return "FormationOfApplicationsAccordingToNeeds";
	
EndFunction

// Complements the action bar with an action when changing the destination.
//
// Parameters:
//  StructureOfActions - Structure - Structure of actions.
//
Procedure StructureOfInsertActionsWhenChangingAssignment(StructureOfActions) Export
	
	StructureOfActions.Insert("WhenChangingDestination");
	
EndProcedure

// Generates a description of the period for the hint when classifying the item and customers.
//
// Parameters:
//  Period - EnumRef.Periodicity - frequency of calculation.
//  NumberOfPeriods - Number - number of calculation periods
//  Subperiod - EnumRef.Periodicity - the number of calculation subperiods.
//
// Returns:
//  String - text description of the calculation period.
//
Function SettingDetails(Period, NumberOfPeriods, Subperiod = Undefined) Export
	
	If Not ValueIsFilled(NumberOfPeriods) Or Not ValueIsFilled(Period) Then
		
		Return NStr("vi = '<kỳ không được chỉ định>';
					|ru = '<период не указан>';
					|en = '<period is not specified>'; fa = '<period is not specified>';
					|it = '<il periodo non è indicato>';
					|pl = '<okres nie jest wskazany>';
					|tr = '<süre belirtilmedi>'");
		
	EndIf;
	
	NumerationItemOptions = "";
	
	If Period = PredefinedValue("Enum.Periodicity.Day") Then
		
		NumerationItemOptions = NStr("vi = 'ngày trước, ngày trước, ngày trước, m,,,,, 0';
									|ru = 'предыдущий день, предыдущих дня, предыдущих дней, м,,,,, 0';
									|en = 'previous day, previous days,,,0'; fa = 'previous day, previous days,,,0';
									|it = 'giorno precedente, giorni precedenti, giorni precedenti, m,,,,, 0';
									|pl = 'poprzedni dzień, poprzednich dnia, poprzednich dni, m,,,,, 0';
									|tr = 'önceki gün, önceki günün, önceki günlerin,,,,,, 0'");
		
	ElsIf Period = PredefinedValue("Enum.Periodicity.Week") Then
		
		NumerationItemOptions = NStr("vi = 'tuần trước, tuần trước, tuần trước, w,,,,, 0';
									|ru = 'предыдущая неделя, предыдущие недели, предыдущих недель, ж,,,,, 0';
									|en = 'previous week, previous weeks,,,0'; fa = 'previous week, previous weeks,,,0';
									|it = 'settimana precedente, settimane precedenti, settimane precedenti, g,,,,, 0';
									|pl = 'poprzednia tydzień, poprzednie tygodnie, poprzednich tygodni, ż,,,,, 0';
									|tr = 'önceki hafta, önceki haftalar, önceki haftaların, f,,,,, 0'");
		
	ElsIf Period = PredefinedValue("Enum.Periodicity.TenDays") Then
		
		NumerationItemOptions = NStr("vi = '10 ngày trước,10 ngày trước,10 ngày trước, w,,,,, 0';
									|ru = 'предыдущая декада, предыдущие декады, предыдущих декад, ж,,,,, 0';
									|en = 'previous ten-day period, previous ten-day periods,,,0'; fa = 'previous ten-day period, previous ten-day periods,,,0';
									|it = 'decade precedente, decade precedenti, decade precedenti, g,,,,, 0';
									|pl = 'poprzednia dekada, poprzednie dekady, poprzednich dekad, ż,,,,, 0';
									|tr = 'önceki 10 günlük süre, önceki 10 günlük süreler, önceki 10 günlük sürelerin, f,,,,, 0'");
		
	ElsIf Period = PredefinedValue("Enum.Periodicity.Month") Then
		
		NumerationItemOptions = NStr("vi = 'tháng trước, tháng trước, tháng trước, m,,,,, 0';
									|ru = 'предыдущий месяц, предыдущих месяца, предыдущих месяцев, м,,,,, 0';
									|en = 'previous month, previous months,,, 0'; fa = 'previous month, previous months,,, 0';
									|it = 'mese precedente, mese precedenti, mese precedenti, m,,,,, 0';
									|pl = 'poprzedni miesiąc, poprzednich miesięcy, poprzednich miesięcy, m,,,,, 0';
									|tr = 'önceki ay, önceki aylar, önceki ayların,,,,,, 0'");
		
	ElsIf Period = PredefinedValue("Enum.Periodicity.Quarter") Then
		
		NumerationItemOptions = NStr("vi = 'quý trước, quý trước, quý trước, m,,,,, 0';
									|ru = 'предыдущий квартал, предыдущих квартала, предыдущих кварталов, м,,,,, 0';
									|en = 'previous quarter, previous quarters,,,0'; fa = 'previous quarter, previous quarters,,,0';
									|it = 'trimestre precedente, trimestre precedenti, trimestre precedenti, m,,,,, 0';
									|pl = 'poprzedni kwartał, poprzednich kwartały, poprzednich kwartałów, m,,,,, 0';
									|tr = 'önceki çeyrek, önceki çeyrekler, önceki çeyreklerin,,,,,, 0'");
		
	ElsIf Period = PredefinedValue("Enum.Periodicity.HalfYear") Then
		
		NumerationItemOptions = NStr("vi = 'nửa năm trước, nửa năm trước, nửa năm trước, с,,,,, 0';
									|ru = 'предыдущее полугодие, предыдущих полугодия, предыдущих полугодий, с,,,,, 0';
									|en = 'previous half-year, previous halves of the year,,,0'; fa = 'previous half-year, previous halves of the year,,,0';
									|it = 'semestre precedenti, semestre precedenti, semestre precedenti, c,,,,, 0';
									|pl = 'poprzednie półrocze, poprzednich półrocze, poprzednie półrocze, s,,,,, 0';
									|tr = 'önceki yarıyıl, önceki yarıyıllar, önceki yarıyılların,,,,,, 0'");
		
	ElsIf Period = PredefinedValue("Enum.Periodicity.Year") Then
		
		NumerationItemOptions = NStr("vi = 'năm trước, năm trước, năm trước, m,,,,, 0';
									|ru = 'предыдущий год, предыдущих года, предыдущих лет, м,,,,, 0';
									|en = 'previous year, previous years,,,0'; fa = 'previous year, previous years,,,0';
									|it = 'anno precedente, anni precedenti, anni precedenti, m,,,,, 0';
									|pl = 'rok poprzedni, lat poprzednich, lata poprzednie, m,,,, 0';
									|tr = 'önceki sene, önceki seneler, önceki yılların,,,,,, 0'");
		
	Else
		
		NumerationItemOptions = "";
		
	EndIf;
	
	SettingPresentation = Lower(NumberInWords(NumberOfPeriods,, NumerationItemOptions));
	
	If ValueIsFilled(Subperiod) Then
		
		If Subperiod = PredefinedValue("Enum.Periodicity.Day") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(theo ngày)';
																	|ru = '(по дням)';
																	|en = '(by day)'; fa = '(by day)';
																	|it = '(per giorni)';
																	|pl = '(wg dni)';
																	|tr = '(günlere göre)'");
			
		ElsIf Subperiod = PredefinedValue("Enum.Periodicity.Week") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(hàng tuần)';
																	|ru = '(по неделям)';
																	|en = '(by weeks)'; fa = '(by weeks)';
																	|it = '(per settimana)';
																	|pl = '(wg tygodni)';
																	|tr = '(haftalara göre)'");
			
		ElsIf Subperiod = PredefinedValue("Enum.Periodicity.TenDays") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(mười ngày)';
																	|ru = '(по декадам)';
																	|en = '(by ten-day periods)'; fa = '(by ten-day periods)';
																	|it = '(per decadi)';
																	|pl = '(wg dekad)';
																	|tr = '(10 günlük sürelere göre)'");
			
		ElsIf Subperiod = PredefinedValue("Enum.Periodicity.Month") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(theo tháng)';
																	|ru = '(по месяцам)';
																	|en = '(by months)'; fa = '(by months)';
																	|it = '(per mese)';
																	|pl = '(wg miesięcy)';
																	|tr = '(aylara göre)'");
			
		ElsIf Subperiod = PredefinedValue("Enum.Periodicity.Quarter") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(hàng quý)';
																	|ru = '(по кварталам)';
																	|en = '(by quarters)'; fa = '(by quarters)';
																	|it = '(per trimestre)';
																	|pl = '(wg kwartałów)';
																	|tr = '(çeyreklere göre)'");
			
		ElsIf Subperiod = PredefinedValue("Enum.Periodicity.HalfYear") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(nửa năm)';
																	|ru = '(по полугодиям)';
																	|en = '(by half-year periods)'; fa = '(by half-year periods)';
																	|it = '(ai semestri)';
																	|pl = '(wg półroczy)';
																	|tr = '(yarıyıllara göre)'");
			
		ElsIf Subperiod = PredefinedValue("Enum.Periodicity.Year") Then
			
			SettingPresentation = SettingPresentation + " " + NStr("vi = '(theo năm)';
																	|ru = '(по годам)';
																	|en = '(by years)'; fa = '(by years)';
																	|it = '(per anno)';
																	|pl = '(wg lat)';
																	|tr = '(yıllara göre)'");
			
		EndIf;
		
	EndIf;
	
	Return SettingPresentation;
	
EndFunction

#EndRegion

