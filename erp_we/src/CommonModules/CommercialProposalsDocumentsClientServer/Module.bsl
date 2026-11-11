////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers documents".
// General module.Commercial Offer Documentsclientserver
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ListSelections

// Sets the selection in the list by the specified value for the desired column
// , taking into account the passed quick selection structure.
//
// Parameters:
//  List                  - DynamicList - the list for which you want to install the selection.
//  ColumnName              - String - name of the column to select from.
//  Value                - Arbitrary - set the value of the selection.
//  QuickFilterStructure - Undefined, Structure - contains selection keys and values.
//  Use           - Undefined, Boolean - indicates whether the selection element is used.
//  Var_ComparisonType            - Undefined, DataCompositionComparisonType - the type of comparison that is set for the selection element.
//  SettingName            - String - name of the form setting that contains the selection value.
//
Procedure SelectionByListValueWhenCreatedOnServer(List, ColumnName, Value, Val QuickFilterStructure, 
			Use = Undefined, Var_ComparisonType = Undefined, SettingName = "") Export
	
	If QuickFilterStructure <> Undefined Then
		
		If IsBlankString(SettingName) Then
			SettingName = ColumnName;
		EndIf;
		
		If QuickFilterStructure.Property(SettingName, Value) Then
			UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
			CommonClientServer.SetDynamicListFilterItem(List, ColumnName, Value, Var_ComparisonType,,UsingSelectionElement);
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets the selection in the list by the specified value for the desired column
// , taking into account the passed quick selection structure.
//
// Parameters:
//  Parameters               - Structure - document list selection settings:
//  * List                - DynamicList - the list for which you want to install the selection.
//  * ColumnName            - String - name of the column to select from.
//  * SettingName          - String - name of the saved setting.
//  * Settings             - DataCompositionSettings  -settings that can be used to get selection values
//  * Use         - Undefined, Boolean - indicates whether the selection element is used.
//  * ComparisonType          - Undefined, DataCompositionComparisonType - the type of comparison that is set for the selection element.
//  Value                - Arbitrary - set the value of the selection.
//  QuickFilterStructure - Undefined, Structure - contains selection keys and values.
//
Procedure SelectingByListValueBeforeLoadingFromSettings(Parameters, Value, Val QuickFilterStructure) Export
	
	List             = Parameters.List;
	ColumnName         = Parameters.ColumnName;
	SettingName       = Parameters.SettingName;
	Settings          = Parameters.Settings;
	Use      = Parameters.Use;
	TypeOfSelectionComparison = Parameters.ComparisonType;
	
	If QuickFilterStructure = Undefined Then
		Value = Settings.Get(SettingName);
		UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
		CommonClientServer.SetDynamicListFilterItem(List, ColumnName, Value, TypeOfSelectionComparison,,UsingSelectionElement);
	Else
		If Not QuickFilterStructure.Property(SettingName) Then
			Value = Settings.Get(SettingName);
			UsingSelectionElement = ?(Use = Undefined, ValueIsFilled(Value), Use);
			CommonClientServer.SetDynamicListFilterItem(List, ColumnName, Value, TypeOfSelectionComparison,,UsingSelectionElement);
		EndIf;
	EndIf;
	
	Settings.Delete(SettingName);
	
EndProcedure

#EndRegion

// Fills in the selection list for selection by relevance.
//
// Parameters:
//  RelevanceSelectionList - ValueList - a list of choices that need to be filled.
//
Procedure FillInSelectionSelectionListByRelevance(RelevanceSelectionList) Export
	
	RelevanceSelectionList.Add("NotExpired",        NStr("vi = 'Chưa hết hạn';
														|ru = 'Не истек';
														|en = 'Not expired'; fa = 'Not expired';
														|it = 'Non scaduto';
														|pl = 'Nie wygasnął';
														|tr = 'Süresi dolan'"));
	RelevanceSelectionList.Add("Expired",          NStr("vi = 'Đã hết hạn';
														|ru = 'Истек';
														|en = 'Expired'; fa = 'منقضی‌شده';
														|it = 'Scaduto';
														|pl = 'Expired';
														|tr = 'Süresi dolmayan'"));
	RelevanceSelectionList.Add("Today",        NStr("vi = 'Hôm nay';
													|ru = 'Сегодня';
													|en = 'Today'; fa = 'امروز';
													|it = 'Oggi';
													|pl = 'Today';
													|tr = 'Bugün'"));
	RelevanceSelectionList.Add("Tomorrow",         NStr("vi = 'Ngày mai';
														|ru = 'Завтра';
														|en = 'Tomorrow'; fa = 'Tomorrow';
														|it = 'Domani';
														|pl = 'Tomorrow';
														|tr = 'Yarın'"));
	RelevanceSelectionList.Add("TheDayAfterTomorrow",    NStr("vi = 'Ngày kia';
																|ru = 'Послезавтра';
																|en = 'The day after tomorrow'; fa = 'The day after tomorrow';
																|it = 'Dopodomani';
																|pl = 'The day after tomorrow';
																|tr = 'Öbür gün'"));
	RelevanceSelectionList.Add("InAWeek",    NStr("vi = 'Trong một tuần';
													|ru = 'Через неделю';
													|en = 'In a week'; fa = 'In a week';
													|it = 'Tra una settimana';
													|pl = 'Za tydzień';
													|tr = 'Bir hafta sonra'"));
	RelevanceSelectionList.Add("ExpiresOnDate", NStr("vi = 'Hết hạn vào ngày...';
													|ru = 'Истекает на дату...';
													|en = 'Expires on date ...'; fa = 'انقضا در تاریخ ...';
													|it = 'Scade il...';
													|pl = 'Dobiega końca w dniu...';
													|tr = 'Son kullanma tarihi...'"));
	
EndProcedure

// Sets the relevance selection passed to the list of documents form.
//
// Parameters:
//  List                  - DynamicList - the list where you want to set the selection.
//  Relevance            - String - line selection based on relevance.
//  EventDate             - Date - the date on which the documents should be considered outdated.
//  CurrentDate             - Date - the current date of the session.
//  QuickFilterStructure - Structure - transferred in the form of a list of documents selected.
//  ChoiceList            - ValueList - the list displayed in the form element.
//
Procedure SelectionByRelevanceWhenCreatingOnServer(List, Relevance, EventDate, CurrentDate, Val QuickFilterStructure, ChoiceList) Export
	
	If QuickFilterStructure <> Undefined Then
		
		QuickFilterStructure.Property("Relevance", Relevance);
		QuickFilterStructure.Property("EventDate",  EventDate);
		
		AddRelevanceListItemIfNecessary(ChoiceList, Relevance, EventDate);
		
		WhenChangingRelevanceSelection(List, Relevance, EventDate, CurrentDate, ChoiceList);
		
	EndIf;
	
EndProcedure

// Sets the selection by relevance and date of relevance in the form of a list of documents.
// Changes the value of the up-to-date date depending on the up-to-date string.
//
// Parameters:
//  List               - DynamicList - a list in which you want to set the selection
//  Relevance         - String - selection line by relevance
//  EventDate          - Date - date on which the document will be expired
//  CurrentDate          - Date - the current date of the session.
//  StandardProcessing - Boolean - flag for performing standard processing when clearing the field value.
//  ChoiceList         - ValueList - a list containing the possible values for selection.
//
Procedure WhenClearingSelectionByRelevance(List, Relevance, EventDate, CurrentDate, StandardProcessing, ChoiceList) Export
	
	StandardProcessing = False;
	If ValueIsFilled(Relevance) Then
		Relevance = "";
		WhenChangingRelevanceSelection(List, Relevance, EventDate, CurrentDate, ChoiceList);
	EndIf;
	
EndProcedure

// Sets the selection by relevance and date of relevance in the form of a list of documents
// Changes the value of the up-to-date date depending on the up-to-date string.
//
// Parameters:
//  List       - DynamicList - a list in which you want to set the selection
//  Relevance - String - selection line by relevance
//  EventDate  - Date - the date on which the documents are considered irrelevant
//  CurrentDate  - Date - the current date of the session.
//  ChoiceList - ValueList - containing the possible values for selection.
//
Procedure WhenChangingRelevanceSelection(List, Relevance, EventDate, CurrentDate, ChoiceList) Export
	
	If Not ValueIsFilled(Relevance) Then
		EventDate      = Date(1,1,1);
	ElsIf Relevance = "Today" Then
		EventDate = CurrentDate;
	ElsIf Relevance = "Tomorrow" Then
		EventDate = CurrentDate + 86400;
	ElsIf Relevance = "TheDayAfterTomorrow" Then
		EventDate = CurrentDate + 2*86400;
	ElsIf Relevance = "InAWeek" Then
		EventDate = CurrentDate + 7*86400;
	ElsIf Relevance = "Expired" Then
		EventDate      = Date(1,1,1);
	ElsIf Relevance = "NotExpired" Then
		EventDate      = Date(1,1,1);
	EndIf;
	
	If Relevance <> "ExpiresOnDateSelected" Then
		DeleteSelectedDateFromList(ChoiceList);
	EndIf;
	
	SetSelectionInListByRelevance(List, Relevance);
	SetSelectionInListByEventDate(List, EventDate);
	
EndProcedure

// Sets in the form of a list of documents selected according to relevance.
//
// Parameters:
//  List - DynamicList - the list where you want to set the selection.
//  Relevance - String - line selection based on relevance.
//
Procedure SetSelectionInListByRelevance(List, Relevance) Export
	
	CommonClientServer.SetDynamicListFilterItem(List, 
		"Expired",
		Relevance = "Expired",
		DataCompositionComparisonType.Equal,,
		Relevance = "NotExpired" Or Relevance = "Expired");
	
EndProcedure

// Removes the item with the selected date from the selection list.
//
// Parameters:
//  ChoiceList - ValueList - the list from which the value is removed.
//
Procedure DeleteSelectedDateFromList(ChoiceList) Export
	
	ListItem = ChoiceList.FindByValue("ExpiresOnDateSelected");
	If ListItem <> Undefined Then
		ChoiceList.Delete(ListItem);
	EndIf;
	
EndProcedure

// Sets in the form of a list of documents selected according to the date of the event.
//
// Parameters:
//  List      - DynamicList - the list where you want to set the selection.
//  EventDate - Date - the date on which the document will be expired.
//
Procedure SetSelectionInListByEventDate(List, EventDate) Export
	
	TypeOfEventDateComparison = DataCompositionComparisonType.LessOrEqual;
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo ngày sự kiện';
			|ru = 'Отбор по дате события';
			|en = 'Filter by event date'; fa = 'Filter by event date';
			|it = 'Selezione per data di evento';
			|pl = 'Filtr wg daty zdarzenia';
			|tr = 'Etkinleştirme tarihi'"), 
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"EventDate",
		TypeOfEventDateComparison,
		EventDate,,
		ValueIsFilled(EventDate));
		
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"EventDate",
		DataCompositionComparisonType.NotEqual,
		Date(1,1,1),,
		ValueIsFilled(EventDate));

EndProcedure

// Determines the visibility of the counterparty field in the document form.
//
// Parameters:
//  AccountingSettings  - Structure - contains settings for account.
//
// Returns:
//   Boolean   - True if the counterparty is visible.
//
Function CounterpartyFieldVisible(AccountingSettings) Export
	
	Return Not (AccountingSettings.PartnersAreUsed 
	            And Not AccountingSettings.IndependentManagementOfPartnersAndCounterparties);
	
EndFunction

// Defines the option for specifying the delivery date based on the values contained in the array.
//
// Parameters:
//  ArrayOfValues  - Array - contains the values of the delivery time.
//
// Returns:
//   EnumRef.DeliveryPeriodOptionsForCommercialProposals - a specific indication option.
//
Function OptionForSpecifyingDeliveryTimeByValue(ArrayOfValues) Export
	
	IndicationOption = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified");
	
	For Each ArrayElement In ArrayOfValues Do
		
		If ValueIsFilled(ArrayElement) Then
			
			If TypeOf(ArrayElement) = Type("Number") Then
				Return PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedInDaysSinceMomentOfOrder");
			Else
				Return PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedAtSpecificDate");
			EndIf;
			
		EndIf;
	
	EndDo;
	
	Return IndicationOption;
	
EndFunction

// Sets up the "delivery Time" column and the command that changes the delivery time, depending on the option specified.
//
// Parameters:
//  OptionToSpecifyDeliveryTerm - EnumRef.DeliveryPeriodOptionsForCommercialProposals - option for specifying.
//  ColumnFormElement          - FormItems - column of the table part containing the delivery time.
//  FormElementCommand          - FormItems - a form element that contains a command that changes the delivery time.
//
Procedure ColumnManagementDeliveryTime(OptionToSpecifyDeliveryTerm, ColumnFormElement, FormElementCommand = Undefined) Export
	
	ColumnFormElement.Visible        = OptionToSpecifyDeliveryTerm <> PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified");
	If FormElementCommand <> Undefined Then
		FormElementCommand.Visible = OptionToSpecifyDeliveryTerm <> PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified");
	EndIf;
	
	ColumnFormElement.ChooseType = False;
	TypeRestriction = New TypeDescription("Undefined");
	If OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedAtSpecificDate") Then
		TypeRestriction = New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date));
	ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedInDaysSinceMomentOfOrder") Then
		TypeRestriction = New TypeDescription("Number",,,New NumberQualifiers(3));
	EndIf;
	ColumnFormElement.TypeRestriction = TypeRestriction;
	ColumnFormElement.Title = TitleDeliveryTime(OptionToSpecifyDeliveryTerm);
	
EndProcedure

// Generates a representation of the delivery time value, depending on the option specified.
//
// Parameters:
//  OptionToSpecifyDeliveryTerm - EnumRef.DeliveryPeriodOptionsForCommercialProposals - option for specifying.
//  DeliveryPeriodDays                 - Number, Date - the value of the delivery time
//
// Returns:
//   String   - the generated representation is the value of the delivery time.
//
Function DeliveryTimeByLine(OptionToSpecifyDeliveryTerm, DeliveryPeriodDays) Export

	DeliveryTimePresentation = "";
	
	If Not ValueIsFilled(DeliveryPeriodDays)
		Or Not ValueIsFilled(OptionToSpecifyDeliveryTerm) Then
		DeliveryTimePresentation = "";
	ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified") Then
		DeliveryTimePresentation = NStr("vi = 'không quan trọng';
										|ru = 'не важно';
										|en = 'doesn''t matter'; fa = 'doesn''t matter';
										|it = 'non importante';
										|pl = 'nie ważne';
										|tr = 'önemsiz'");
	ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedInDaysSinceMomentOfOrder") Then
		DeliveryTimePresentation = StrTemplate(NStr("vi = 'trong vòng %1 ngày';
													|ru = 'в течение %1 дн.';
													|en = 'during %1 days.'; fa = 'during %1 days.';
													|it = 'entro %1 giorni';
													|pl = 'w ciągu %1 dn.';
													|tr = '%1 gün içerisinde'"), DeliveryPeriodDays);
	ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedAtSpecificDate") Then
		DeliveryTimePresentation = Format(DeliveryPeriodDays,"DLF=D");
	EndIf;
	
	Return DeliveryTimePresentation;
	
EndFunction

// Forms the title of the "delivery Time" column.
//
// Parameters:
//  OptionToSpecifyDeliveryTerm - EnumRef.DeliveryPeriodOptionsForCommercialProposals - option for specifying.
//
// Returns:
//   String   - the generated column header.
//
Function TitleDeliveryTime(OptionToSpecifyDeliveryTerm) Export
	
	If OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedAtSpecificDate") Then
		Return NStr("vi = 'Ngày giao';
					|ru = 'Дата поставки';
					|en = 'Delivery date'; fa = 'تاریخ تحویل';
					|it = 'Data di spedizione';
					|pl = 'Data dostawy';
					|tr = 'Tedarik tarihi'");
	ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedInDaysSinceMomentOfOrder") Then
		Return NStr("vi = 'Thời gian giao hàng (ngày)';
					|ru = 'Срок поставки (дн.)';
					|en = 'Delivery period (days)'; fa = 'مدت تحویل (روز)';
					|it = 'Termine di consegna (giorni)';
					|pl = 'Termin dostawy (dn.)';
					|tr = 'Teslimat süresi (gün)'");
	Else
		Return "";
	EndIf;
	
EndFunction

// Clears the delivery time in the table column if it does not match the option specified.
//
// Parameters:
//  TabularSection               - TabularSection - it contains a column with the delivery date.
//  AttributeName                 - String - name of the table part detail that contains the delivery date.
//  OptionToSpecifyDeliveryTerm - EnumRef.DeliveryPeriodOptionsForCommercialProposals - option for specifying.
//
Procedure ClearDeliveryTimeIfDoesNotMatchOption(TabularSection, AttributeName, OptionToSpecifyDeliveryTerm) Export
	
	For Each LineOfATabularSection In  TabularSection Do
		
		If  OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified") Then
			If ValueIsFilled(LineOfATabularSection[AttributeName]) Then
				LineOfATabularSection[AttributeName] = Undefined;
			EndIf;
		ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedInDaysSinceMomentOfOrder") Then
			If TypeOf(LineOfATabularSection[AttributeName]) <> Type("Number") Then
				LineOfATabularSection[AttributeName] = 0;
			EndIf;
		ElsIf OptionToSpecifyDeliveryTerm = PredefinedValue("Enum.DeliveryPeriodOptionsForCommercialProposals.SpecifiedAtSpecificDate") Then
			If TypeOf(LineOfATabularSection[AttributeName]) <> Type("Date") Then
				LineOfATabularSection[AttributeName] = Date(1, 1, 1);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Creates a view of the item to print.
//
// Parameters:
//  Products   - DefinedType.EDLProducts - Nomenclature.
//  Characteristic - DefinedType.ItemsCharacteristicEDL - characteristic.
//
// Returns:
//   String   - the generated representation of the nomenclature for printing.
//
Function PresentationOfProductsForPrinting(Products, Characteristic) Export

	PresentationForPrinting = "";
	StandardProcessing = True;
	
	CommercialProposalsDocumentsClientServerOverridable.CreatePresentationOfProductsForPrinting(PresentationForPrinting, Products, Characteristic, StandardProcessing);
	
	If Not StandardProcessing Then
		Return PresentationForPrinting;
	EndIf;
	
	If ValueIsFilled(Characteristic) Then
		Return StrTemplate(NStr("vi = '%1 (%2)';
								|ru = '%1 (%2)';
								|en = '%1 (%2)'; fa = '%1 (%2)';
								|it = '%1 (%2)';
								|pl = '%1 (%2)';
								|tr = '%1 (%2)'"), Products, Characteristic);
	Else
		Return Products;
	EndIf;

EndFunction

// Description of parameters for selecting the document list form.
//
// Returns:
//  Structure - contains fields:
//  * List        - DynamicList - the list for which you want to install the selection.
//  * ColumnName    - String - name of the column to select from.
//  * SettingName  - String - name of the saved setting.
//  * Settings     - DataCompositionSettings  -settings that can be used to get selection values
//  * Use - Undefined, Boolean - indicates whether the selection element is used.
//  * ComparisonType  - Undefined, DataCompositionComparisonType - the type of comparison that is set for the selection element.
//
Function SelectionOptionsBeforeLoadingFromSettings() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("List", Undefined);
	Parameters.Insert("ColumnName", "");
	Parameters.Insert("SettingName", "");
	Parameters.Insert("Settings", Undefined);
	Parameters.Insert("Use", Undefined);
	Parameters.Insert("ComparisonType", Undefined);
	
	Return Parameters;
	
EndFunction

// Sets the list of documents in the form of a selection by relevance, saved in the settings
// Selection from the settings is set only if the selection is not passed to the form from the outside.
//
// Parameters:
//  List                  - DynamicList - the list where you want to set the selection.
//  Relevance            - String - line selection based on relevance.
//  EventDate             - Date - the date on which the documents should be considered outdated.
//  CurrentDate             - Date - the current date of the session.
//  QuickFilterStructure - Structure - transferred in the form of a list of documents selected.
//  Settings               - Map - form settings.
//  ChoiceList            - ValueList - a list containing the possible values for selection.
//
Procedure SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, EventDate, CurrentDate, Val QuickFilterStructure, Settings, ChoiceList) Export
	
	If QuickFilterStructure = Undefined Then
		
		Relevance     = Settings.Get("Relevance");
		EventDate      = Settings.Get("EventDate");
		
		WhenChangingRelevanceSelection(List, Relevance, EventDate, CurrentDate, ChoiceList);
		
	Else
		
		If Not QuickFilterStructure.Property("Relevance") Then
			Relevance = Settings.Get("Relevance");
		EndIf;
		
		If Not QuickFilterStructure.Property("EventDate") Then
			EventDate = Settings.Get("EventDate");
		EndIf;
		
		WhenChangingRelevanceSelection(List, Relevance, EventDate, CurrentDate, ChoiceList);
		
	EndIf;
	
	AddRelevanceListItemIfNecessary(ChoiceList, Relevance, EventDate);
	
	Settings.Delete("Relevance");
	Settings.Delete("EventDate");
	
EndProcedure

// The method of placement on the Bidzaar ETP.
// 
// Returns:
//  Number - Bidzaar Placement Method
Function BidzaarPlacementMethod() Export
	
	Return 2;
	
EndFunction

#EndRegion

#Region Internal

Procedure SetImageAddress(Image, PictureAddress, PanelIsDisplayed, UUID) Export
	
	If Not PanelIsDisplayed Then
		Return;
	EndIf;
	
	If ValueIsFilled(PictureAddress) Then
		Return;	
	EndIf;
		
	If Not ValueIsFilled(Image) Then
		Return;
	EndIf;
	
	
EndProcedure

#EndRegion

#Region Private

Procedure AddRelevanceListItemIfNecessary(ChoiceList, Relevance, EventDate)
	
	If Relevance = "ExpiresOnDate"
		Or Relevance = "ExpiresOnDateSelected" Then
		
		SelectionPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hết hạn vào ngày %1';
																								|ru = 'Истекает на дату %1';
																								|en = 'Expires on %1'; fa = 'Expires on %1';
																								|it = 'Scade il %1';
																								|pl = 'Dobiega końca w dniu %1';
																								|tr = 'Son kullanma tarihi %1'"), Format(EventDate, "DLF=D"));
		ChoiceList.Add("ExpiresOnDateSelected", SelectionPresentation);
		
		Relevance = "ExpiresOnDateSelected";
		
	EndIf;
	
EndProcedure

#EndRegion
