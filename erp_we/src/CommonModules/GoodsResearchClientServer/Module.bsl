
#Region Public

#Region GoodsResearchSheets

// Returns parameters for selecting a product research map for the item.
// 
// Returns:
// 	Structure - From:
//  * ChoiceParameterLinks - Map of KeyAndValue:
//	 ** Key - String - The type of setting for which you need to get a communication key.
//	 ** Value - String - unique identifier.
//  * DetailsOfGoodsResearchCard - String - List of Product research card Attributes
//
Function ParametersForSelectingResearchAssignmentConstructor() Export
	
	ChoiceParameters = New Structure();
	
	ChoiceParameters.Insert("ChoiceParameterLinks", New Map);
	
	// To obtain the Attributes of the selected goods research card
	ChoiceParameters.Insert("DetailsOfGoodsResearchCard", "");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region AutoSelection_SelectionByProperties

// Returns a predefined link key for selecting by properties depending on the type of setting.
//
// Parameters:
//   SettingKind - String - The type of setting for which you need to get a communication key
//
// Returns:
//   UUID - Link key for selection by properties
Function SelectionByPropertiesOfCommunicationKey(SettingKind) Export
		
	If SettingKind = "Products" Then
		
		Return New UUID("5550a108-5e2e-11f0-9fe2-0242ac120002");
		
	ElsIf SettingKind = "Characteristic" Then
		
		Return New UUID("6a39e714-5e2e-11f0-9fe2-0242ac120002");
		
	Else
		
		Raise NStr("vi = 'Để có được khóa chọn cho các thuộc tính, chế độ xem không chính xác của cài đặt đã được chuyển.';
					|ru = 'Для получения ключа отбора по свойствам передан неверный вид настройки.';
					|en = 'An invalid setting kind was passed to receive a filter key by properties'; fa = 'An invalid setting kind was passed to receive a filter key by properties';
					|it = 'Per ricevere la chiave di selezione per le proprietà è stato trasferito un tipo di impostazione non corretto.';
					|pl = 'W celu otrzymania klucza filtru wg właściwości został przekazany błędny rodzaj ustawienia.';
					|tr = 'Özelliklere göre seçim anahtarının alınması için yanlış ayar türü aktarıldı.'");
		
	EndIf;
	
EndFunction

#EndRegion

#Region Other

// Generates an array of selection conditions by properties
// 
// Returns:
// 	Array of Structure - From:
// 		* Id - String - condition ID
// 		* Presentation - String - condition representation
// 		* Comparison - Boolean - flag of the comparison condition
// 		* Template - String - the pattern condition
Function ListOfSelectionCriteriaByProductProperties()
	
	Result = New Array;
	
	Condition = New Structure;
	Condition.Insert("Id", "Equal");
	Condition.Insert("Presentation", NStr("vi = 'Bằng';
											|ru = 'Равно';
											|en = 'Equal to'; fa = 'برابر با';
											|it = 'Uguale';
											|pl = 'Równa się';
											|tr = 'Eşit'"));
	Condition.Insert("Comparison", False);
	Condition.Insert("Template", "%1 = %2");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "NotEqual");
	Condition.Insert("Presentation", NStr("vi = 'Không bằng';
											|ru = 'Не равно';
											|en = 'Not equal to'; fa = 'نابرابر با';
											|it = 'Non equo';
											|pl = 'Nie równa się';
											|tr = 'Eşit değil'"));
	Condition.Insert("Comparison", False);
	Condition.Insert("Template", "%1 <> %2");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "Greater");
	Condition.Insert("Presentation", NStr("vi = 'Lớn hơn';
											|ru = 'Больше';
											|en = 'Greater than'; fa = 'Greater than';
											|it = 'Maggiore';
											|pl = 'Więcej';
											|tr = 'Büyük'"));
	Condition.Insert("Comparison", True);
	Condition.Insert("Template", "%1 > %2");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "GreaterOrEqual");
	Condition.Insert("Presentation", NStr("vi = 'Hơn hoặc bằng';
											|ru = 'Больше или равно';
											|en = 'Greater than or equal'; fa = 'Greater than or equal';
											|it = 'Maggiore o uguale';
											|pl = 'Więcej lub równo';
											|tr = 'Büyüktür veya eşittir'"));
	Condition.Insert("Comparison", True);
	Condition.Insert("Template", "%1 >= %2");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "Less");
	Condition.Insert("Presentation", NStr("vi = 'Nhỏ hơn';
											|ru = 'Меньше';
											|en = 'Less'; fa = 'Less';
											|it = 'Minore';
											|pl = 'Mniej';
											|tr = 'Küçük'"));
	Condition.Insert("Comparison", True);
	Condition.Insert("Template", "%1 < %2");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "LessOrEqual");
	Condition.Insert("Presentation", NStr("vi = 'Ít hơn hoặc bằng';
											|ru = 'Меньше или равно';
											|en = 'Less than or equal'; fa = 'Less than or equal';
											|it = 'Minore o uguale';
											|pl = 'Mniej lub równo';
											|tr = 'Küçüktür veya eşittir'"));
	Condition.Insert("Comparison", True);
	Condition.Insert("Template", "%1 <= %2");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "InList");
	Condition.Insert("Presentation", NStr("vi = 'Trong danh sách';
											|ru = 'В списке';
											|en = 'In list'; fa = 'در فهرست';
											|it = 'Nella lista';
											|pl = 'W liście';
											|tr = 'Listede'"));
	Condition.Insert("Comparison", False);
	Condition.Insert("Template", "%1 IN (%2)");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "NotInList");
	Condition.Insert("Presentation", NStr("vi = 'Không trong danh sách';
											|ru = 'Не в списке';
											|en = 'Not in list'; fa = 'نه در فهرست';
											|it = 'Non nella lista';
											|pl = 'Nie w liście';
											|tr = 'Listede değil'"));
	Condition.Insert("Comparison", False);
	Condition.Insert("Template", "NOT %1 IN (%2)");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "InInterval");
	Condition.Insert("Presentation", NStr("vi = 'Trong khoảng (>, <)';
											|ru = 'В интервале (>,<)';
											|en = 'Within interval (>,<)'; fa = 'Within interval (>,<)';
											|it = 'Nell''intervallo (>,<)';
											|pl = 'W przedziale (>,<)';
											|tr = 'Aralığı (>,<)'"));
	Condition.Insert("Comparison", True);
	Condition.Insert("Template", "%1 > %2 AND %1 < %3");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "InIntervalIncluding");
	Condition.Insert("Presentation", NStr("vi = 'Trong khoảng (> =, <=)';
											|ru = 'В интервале (>=,<=)';
											|en = 'Within interval (>=,<=)'; fa = 'Within interval (>=,<=)';
											|it = 'Nell''intervallo (>=,<=)';
											|pl = 'W przedziale (>=,<=)';
											|tr = 'Aralığı (>=,<=)'"));
	Condition.Insert("Comparison", True);
	Condition.Insert("Template", "%1 >= %2 AND %1 <= %3");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "Filled");
	Condition.Insert("Presentation", NStr("vi = 'Đã điền';
											|ru = 'Заполнено';
											|en = 'Filled'; fa = 'پرشده';
											|it = 'Compilato';
											|pl = 'Wypełniono';
											|tr = 'Dolduruldu'"));
	Condition.Insert("Comparison", False);
	Condition.Insert("Template", "NOT %1 IN (UNDEFINED, FALSE, 0)");
	Result.Add(Condition);
	
	Condition = New Structure;
	Condition.Insert("Id", "NotFilled");
	Condition.Insert("Presentation", NStr("vi = 'Chưa điền';
											|ru = 'Не заполнено';
											|en = 'Not filled'; fa = 'Not filled';
											|it = 'Non compilato';
											|pl = 'Nie wypełnione';
											|tr = 'Boş'"));
	Condition.Insert("Comparison", False);
	Condition.Insert("Template", "%1 IN (UNDEFINED, FALSE, 0)");
	Result.Add(Condition);
	
	Return Result;
	
EndFunction

Function StructureOfSelectionConditionsByProductProperties() Export
	
	ConditionsStructure = New Structure;
	
	Conditions = ListOfSelectionCriteriaByProductProperties();
	For Each Condition In Conditions Do
		
		ConditionProperties = StructureOfSelectionConditionByProductProperties(Condition);
		
		ConditionsStructure.Insert(Condition.Id, ConditionProperties);
		
	EndDo;
	
	Return ConditionsStructure;
	
EndFunction

// Constructor of the selection criteria structure by properties
// 
// Parameters:
// 	Condition - Structure - From:
// 		* Id - String - condition ID
// 		* Presentation - String - condition representation
// 		* Comparison - Boolean - flag of the comparison condition
// 		* Template - String - the pattern condition
// Returns:
// 	Structure - From:
//		* Id - String - condition ID
//		* Presentation - String - condition representation
//		* Comparison - Boolean - flag of the comparison condition
//		* Template - String - the pattern condition
//		* List - Boolean - a sign for working with a list
//		* Interval - Boolean - indicates an interval condition
//		* Fullness - Boolean - indicates the condition for checking fullness
//		* Including - Boolean - flag for a condition that includes a border
//		* Reverse_1 - Boolean - inversion flag in the condition
Function StructureOfSelectionConditionByProductProperties(Condition) Export
	
	ConditionsIncluding  = StrSplit("Equal,InList,GreaterOrEqual,LessOrEqual,InIntervalIncluding", ",");
	ConditionsAreReversed = StrSplit("NotEqual,NotInList", ",");
	
	Result = New Structure;
	
	Result.Insert("Id", Condition.Id);
	Result.Insert("Presentation", Condition.Presentation);
	Result.Insert("Comparison",     Condition.Comparison);
	Result.Insert("Template",        Condition.Template);
	Result.Insert("List",        StrFind(Condition.Id, "InList") > 0);
	Result.Insert("Interval",      StrFind(Condition.Id, "InInterval") > 0);
	Result.Insert("Fullness", StrFind(Condition.Id, "Filled") > 0);
	Result.Insert("Including",       ConditionsIncluding.Find(Condition.Id) <> Undefined);
	Result.Insert("Reverse_1",      ConditionsAreReversed.Find(Condition.Id) <> Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion