
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	WorkCenterType = Parameters.WorkCenterType;
	
	CommonClientServer.SetDynamicListFilterItem(ListSetupOptions, "Owner", WorkCenterType);
	
	ChangeoverTimeUnit = Common.ObjectAttributeValue(WorkCenterType, "ChangeoverTimeUnit");
	If ChangeoverTimeUnit = Enums.TimeMeasureUnits.Minute Then
		ChangeoverTimeUnitAsAString = NStr("vi = 'tính bằng phút';
											|ru = 'в минутах';
											|en = 'in minutes'; fa = 'in minutes';
											|it = 'in minuti';
											|pl = 'w minutach';
											|tr = 'dakika cinsinden'");
	ElsIf ChangeoverTimeUnit = Enums.TimeMeasureUnits.Hour Then
		ChangeoverTimeUnitAsAString = NStr("vi = 'tính bằng giờ';
											|ru = 'в часах';
											|en = 'in hours'; fa = 'به ساعت';
											|it = 'in ore';
											|pl = 'w godzinach';
											|tr = 'saat cinsinden'");
	ElsIf ChangeoverTimeUnit = Enums.TimeMeasureUnits.Days1 Then
		ChangeoverTimeUnitAsAString = NStr("vi = 'trong ngày';
											|ru = 'в сутках';
											|en = 'in days'; fa = 'in days';
											|it = 'in giorni';
											|pl = 'w dobach';
											|tr = 'gün cinsinden'");
	EndIf; 
	
	UpdateChangeoverDurationTableOnServer();
	
	If Not AccessRight("Edit", Metadata.InformationRegisters.ChangeoverDurationTime) Then
		Items.ChangeoverDurationTable.ReadOnly = True;
	EndIf; 

	SetColorDesignOfAdjustmentOptions();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SetupOptions" 
		Or EventName = "Write_WorkCenterTypes" Then
		UpdateChangeoverDurationTableOnServer();
	EndIf; 
	
	If EventName = "Write_SetupOptions" Then
		SetColorDesignOfAdjustmentOptions();
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChangeoverDurationTable

&AtClient
Procedure ChangeoverDurationTableOnActivateCell(Item)
	
	SettingComment = New FormattedString("");
	OwnerSettingIndex = -1;
	
	CurTableField = Items.ChangeoverDurationTable.CurrentItem;
	If CurTableField = Undefined Then
		Return
	EndIf; 
	
	If StrFind(CurTableField.Name, "SetupSettings") = 0 Then
		Return
	EndIf; 
	
	FieldIndex = IndexOfFieldByElementName(CurTableField.Name);
	
	TextInTableIsHighlightedInColor = New FormattedString(NStr("vi = 'màu xanh lục';
																|ru = 'темно-синим цветом';
																|en = 'navy blue'; fa = 'navy blue';
																|it = 'in blu scuro';
																|pl = 'granatowym kolorem';
																|tr = 'koyu mavi renk ile'"), New Font(,,True), WebColors.DarkBlue);
	
	CurrentData = Items.ChangeoverDurationTable.CurrentData;
	SettingsPriority = CurrentData["SetupSettings" + FieldIndex + "Priority"];
	If Not CurrentData["SetupSettings" + FieldIndex + "Available"] Then
		
		SettingComment = New FormattedString(NStr("vi = 'Không thể chỉ ra một thời lượng đối với nhiều phương án cài đặt.';
													|ru = 'Не допускается указывать длительность для одного и того же варианта наладки.';
													|en = 'It is not allowed to specify duration for the same setup settings.'; fa = 'It is not allowed to specify duration for the same setup settings.';
													|it = 'Non è consentito specificare la durata per la stessa opzione di configurazione.';
													|pl = 'Określanie czasu trwania dla tego samego wariantu dostosowania jest niedopuszczalne.';
													|tr = 'Aynı ekipman kurulum ayarı için süre belirtmeye izin verilmemektedir.'"));
		
	ElsIf CurrentData["SetupSettings" + FieldIndex + "Time"] = 0 Then
		
		SettingComment = New FormattedString(NStr("vi = 'Chưa chỉ ra thời lượng.';
													|ru = 'Длительность не указана.';
													|en = 'Duration is not specified.'; fa = 'Duration is not specified.';
													|it = 'La durata non è specificata.';
													|pl = 'Czas trwania nie ukazany.';
													|tr = 'Süre belirtilmedi.'"));
		
	ElsIf SettingsPriority = 1 Then
		
		SettingComment = New FormattedString(NStr("vi = 'Thời lượng được xác định theo tùy chỉnh cá nhân.';
													|ru = 'Длительность определяется по индивидуальной настройке.';
													|en = 'Duration is determined by custom changeover.'; fa = 'Duration is determined by custom changeover.';
													|it = 'La durata viene determinata in base alla singola impostazione.';
													|pl = 'Czas trwania jest określany wg ustawień indywidualnych.';
													|tr = 'Süre, bireysel ayarlara göre tanımlanmaktadır.'"));
		
	ElsIf SettingsPriority = 2 Then
		
		ExplanationForSettingUpText = NStr("vi = 'Thời lượng được xác định theo tùy chỉnh từ phương án cài đặt ""Phương án cài đặt bất kỳ"" sang ""%1""';
											|ru = 'Длительность определяется по настройке с варианта наладки ""Любой вариант наладки"" на ""%1""';
											|en = 'Duration is determined by changeover from ""Any setup settings"" to setup settings ""%1""'; fa = 'Duration is determined by changeover from ""Any setup settings"" to setup settings ""%1""';
											|it = 'La durata viene determinata in base all''impostazione dalla variante di configurazione ""Qualsiasi variante di configurazione"" a ""%1""';
											|pl = 'Czas trwania jest określany wg ustawień z wariantu dostosowania ""Любой вариант наладки"" na ""%1""';
											|tr = 'Süre, ""Herhangi Ekipman Kurulum Ayarı"" üzerinden ""%1"" olarak ekipman kurulum ayarlarından tanımlanmaktadır.'");
		ExplanationForSettingUpText = StringFunctionsClientServer.SubstituteParametersToString(
										ExplanationForSettingUpText, 
										ChangeoverDurationTable[Number(FieldIndex)].FirstColumn);
		SettingComment = New FormattedString(ExplanationForSettingUpText, " ", NStr("vi = '(trong bảng đã chọn';
																					|ru = '(в таблице выделена';
																					|en = '(highlighted in'; fa = '(highlighted in';
																					|it = '(nella tabella è selezionata';
																					|pl = '(w tabeli zaznaczona';
																					|tr = '(tabloda vurgulanan'"), " ", TextInTableIsHighlightedInColor, ").");
		
	ElsIf SettingsPriority = 3 Then
		
		ExplanationForSettingUpText = NStr("vi = 'Thời lượng được xác định theo tùy chỉnh từ phương án cài đặt ""%1"" sang ""Phương án cài đặt bất kỳ""';
											|ru = 'Длительность определяется по настройке с варианта наладки ""%1"" на ""Любой вариант наладки""';
											|en = 'Duration is determined by changeover from setup settings ""%1"" to ""Any setup settings""'; fa = 'Duration is determined by changeover from setup settings ""%1"" to ""Any setup settings""';
											|it = 'La durata viene determinata in base all''impostazione dalla variante di configurazione ""%1"" a ""Qualsiasi variante di configurazione""';
											|pl = 'Czas trwania jest określany wg ustawień z wariantu dostosowania ""%1"" na ""Dowolny wariant dostosowania""';
											|tr = 'Süre, ""%1"" üzerinden ""Herhangi Ekipman Kurulum Ayarı"" olarak ekipman kurulum ayarlarından tanımlanmaktadır.'");
		ExplanationForSettingUpText = StringFunctionsClientServer.SubstituteParametersToString(
										ExplanationForSettingUpText, 
										CurrentData.FirstColumn);
		SettingComment = New FormattedString(ExplanationForSettingUpText, " ", NStr("vi = '(trong bảng đã chọn';
																					|ru = '(в таблице выделена';
																					|en = '(highlighted in'; fa = '(highlighted in';
																					|it = '(nella tabella è selezionata';
																					|pl = '(w tabeli zaznaczona';
																					|tr = '(tabloda vurgulanan'"), " ", TextInTableIsHighlightedInColor, ").");
		
	ElsIf SettingsPriority = 4 Then
		
		ExplanationForSettingUpText = NStr("vi = 'Thời lượng được xác định theo tùy chỉnh đối với dạng nguồn lực sản xuất nói chung';
											|ru = 'Длительность определяется по настройке для вида рабочего центра в целом';
											|en = 'Duration is determined by changeover for the entire work center type'; fa = 'Duration is determined by changeover for the entire work center type';
											|it = 'La durata viene determinata dall''impostazione per il tipo di centro di lavoro nel suo complesso';
											|pl = 'Czas trwania jest określany wg ustawień dla rodzaju centrum pracy ogółem';
											|tr = 'Süre, iş merkezi genel türü için ayarlardan tanımlanmaktadır'");
		SettingComment = New FormattedString(ExplanationForSettingUpText, " ", NStr("vi = '(trong bảng đã chọn';
																					|ru = '(в таблице выделена';
																					|en = '(highlighted in'; fa = '(highlighted in';
																					|it = '(nella tabella è selezionata';
																					|pl = '(w tabeli zaznaczona';
																					|tr = '(tabloda vurgulanan'"), " ", TextInTableIsHighlightedInColor, ").");
		
	Else	
		
		SettingComment = New FormattedString("");
		
	EndIf; 
	
	OwnerSettingIndex = CurrentData["SetupSettings" + FieldIndex + "OwnerSettingIndex"];
	
EndProcedure

&AtClient
Procedure ChangeoverDurationTableOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return
	EndIf;
	
	CurrentData = Items.ChangeoverDurationTable.CurrentData;
	
	CurrentSetupSettings = SetupOptionsInTable.Get(ChangeoverDurationTable.IndexOf(CurrentData)).Value;
	
	RowData = New Array;
	
	SettingOptionNumber = 0;
	For Each ConsiderFollowingAdjustmentOption In SetupOptionsInTable Do
		CommonPropsName = "SetupSettings" + Format(SettingOptionNumber, "NZ=0; NG=");
		NextSetupSettings = SetupOptionsInTable.Get(SettingOptionNumber).Value;
		SettingOptionNumber = SettingOptionNumber + 1;
		
		If CurrentSetupSettings = NextSetupSettings And ValueIsFilled(CurrentSetupSettings) 
			Or CurrentData[CommonPropsName + "SettingIsInherited"] Then
			Continue;
		EndIf;
		
		ChangeoverData = New Structure;
		ChangeoverData.Insert("CurrentSetupSettings",   CurrentSetupSettings);
		ChangeoverData.Insert("NextSetupSettings", NextSetupSettings);
		ChangeoverData.Insert("ChangeoverTime",        CurrentData[CommonPropsName + "Time"]);
		RowData.Add(ChangeoverData);
		
	EndDo; 
	
	DurationOfChangeoverArray = ChangeoverTimeTableAtEndOfEditingOnServer(RowData, WorkCenterType);
	
	UpdateChangeoverDuration(DurationOfChangeoverArray);
	
	Notify("Write_ChangeoverDurationTime");
	
EndProcedure

&AtClient
Procedure Attachable_ChangeoverDurationTableAnyEquipmentSetupSettingTimeWhenChanging(Item)
	
	CurrentData = Items.ChangeoverDurationTable.CurrentData;
	FieldIndex = IndexOfFieldByElementName(Item.Name);
	
	If CurrentData["SetupSettings" + FieldIndex + "SettingIsInherited"]
		And CurrentData["SetupSettings" + FieldIndex + "Time"] <> 0 Then
		CurrentData["SetupSettings" + FieldIndex + "SettingIsInherited"] = False;
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region FillingInChangeoverDurationTable

&AtServer
Procedure UpdateChangeoverDurationTableOnServer()

	TableName = "ChangeoverDurationTable";
	
	ChangeoverDurationTable.Clear();
	SetupOptionsInTable.Clear();
	OwnerSettingIndex = -1;
	
	AttributesToBeDeleted = New Array;
	For Each AttributeToDelete In AddedAttributes Do
		AttributesToBeDeleted.Add("ChangeoverDurationTable." + AttributeToDelete + "Time");										
		AttributesToBeDeleted.Add("ChangeoverDurationTable." + AttributeToDelete + "Available");										
		AttributesToBeDeleted.Add("ChangeoverDurationTable." + AttributeToDelete + "SettingIsInherited");										
		AttributesToBeDeleted.Add("ChangeoverDurationTable." + AttributeToDelete + "Priority");										
		AttributesToBeDeleted.Add("ChangeoverDurationTable." + AttributeToDelete + "OwnerSettingIndex");										
		AttributesToBeDeleted.Add("ChangeoverDurationTable." + AttributeToDelete + "SettingIndex");										
	EndDo;	
	
	DeleteAddedItems();
	
	TableSetupOptions = TableSetupOptions(WorkCenterType);
	
	AddDetailsToTable(TableSetupOptions, AttributesToBeDeleted);
	AddBankingDetailsToForm(TableSetupOptions);
	FillInChangeoverTable(TableSetupOptions);
	
EndProcedure

// Parameters:
// 	WorkCenterType - CatalogRef.WorkCenterTypes - 
// Returns:
// 	ValueTable - Where:
// 		* SetupSettings - CatalogRef.SetupOptions - 
// 		* Description - String - 
&AtServer
Function TableSetupOptions(WorkCenterType)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SetupOptions.Ref AS SetupSettings,
	|	SetupOptions.Description AS Description,
	|	2 AS Queue
	|FROM
	|	Catalog.SetupOptions AS SetupOptions
	|WHERE
	|	SetupOptions.Owner = &WorkCenterType
	|	AND NOT SetupOptions.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.SetupOptions.EmptyRef),
	|	&AnySetupSettings,
	|	1
	|
	|ORDER BY
	|	Queue,
	|	Description";
	
	Query.SetParameter("WorkCenterType", WorkCenterType);
	Query.SetParameter("AnySetupSettings", NStr("vi = 'Phương án cài đặt bất kỳ';
												|ru = 'Любой вариант наладки';
												|en = 'Any setup settings'; fa = 'هر تنظیمات راه‌اندازی';
												|it = 'Qualsiasi variante di configurazione';
												|pl = 'Dowolny wariant dostosowania';
												|tr = 'Herhangi bir ekipman kurulum seçeneği'"));
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure DeleteAddedItems()

	TableName = "ChangeoverDurationTable";
	
	For Each CommonPropsName In AddedAttributes Do
		// Time
		TagName = TableName + CommonPropsName.Value + "Time";
		Items.Delete(Items[TagName]);
	EndDo;
	
	AddedAttributes.Clear();
	
EndProcedure

&AtServer
Procedure AddDetailsToTable(TableSetupOptions, AttributesToBeDeleted)

	AttributesToBeAdded = New Array;
	
	SettingOptionNumber = 0;
	For Each Selection In TableSetupOptions Do
		CommonPropsName = "SetupSettings" + Format(SettingOptionNumber, "NZ=0; NG=");
		SettingOptionNumber = SettingOptionNumber + 1;
		
		If Selection.SetupSettings = Catalogs.SetupOptions.EmptyRef() Then
			// The props for any setup option are already there
			Continue;
		EndIf;
		
		// Time
		AttributeName = CommonPropsName + "Time";
		NewAttribute = New FormAttribute(
								AttributeName, 
								New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)), 
								"ChangeoverDurationTable", 
								Selection.Description);
		AttributesToBeAdded.Add(NewAttribute);
		
		// Available
		AttributeName = CommonPropsName + "Available";
		NewAttribute = New FormAttribute(
								AttributeName, 
								New TypeDescription("Boolean"), 
								"ChangeoverDurationTable");
		AttributesToBeAdded.Add(NewAttribute);
		
		// SettingIsInherited
		AttributeName = CommonPropsName + "SettingIsInherited";
		NewAttribute = New FormAttribute(
								AttributeName, 
								New TypeDescription("Boolean"), 
								"ChangeoverDurationTable");
		AttributesToBeAdded.Add(NewAttribute);
		
		// Priority
		AttributeName = CommonPropsName + "Priority";
		NewAttribute = New FormAttribute(
								AttributeName, 
								New TypeDescription("Number", New NumberQualifiers(1, 0, AllowedSign.Nonnegative)), 
								"ChangeoverDurationTable");
		AttributesToBeAdded.Add(NewAttribute);
		
		// OwnerSettingIndex
		AttributeName = CommonPropsName + "OwnerSettingIndex";
		NewAttribute = New FormAttribute(
								AttributeName, 
								New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Any)), 
								"ChangeoverDurationTable");
		AttributesToBeAdded.Add(NewAttribute);
		
		// SettingIndex
		AttributeName = CommonPropsName + "SettingIndex";
		NewAttribute = New FormAttribute(
								AttributeName, 
								New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)), 
								"ChangeoverDurationTable");
		AttributesToBeAdded.Add(NewAttribute);
		
		AddedAttributes.Add(CommonPropsName);
	EndDo;
	ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);

EndProcedure

&AtServer
Procedure AddBankingDetailsToForm(TableSetupOptions)

	TableName = "ChangeoverDurationTable";
	
	SettingOptionNumber = 0;
	For Each Selection In TableSetupOptions Do
		
		SetupOptionsInTable.Add(Selection.SetupSettings, Selection.Description);
		
		CommonPropsName = "SetupSettings" + Format(SettingOptionNumber, "NZ=0; NG=");
		SettingOptionNumber = SettingOptionNumber + 1;
		
		AddConditionalAppearance(CommonPropsName);
		
		If Selection.SetupSettings = Catalogs.SetupOptions.EmptyRef() Then
			// The props for any setup option are already there
			Continue;
		EndIf;
		
		// Time
		AttributeName = CommonPropsName + "Time";
		TimeElement = Items.Add(TableName + AttributeName, Type("FormField"), Items.TheDurationOfTheConversionTableGroupOptionsSetup);
		TimeElement.Type = FormFieldType.InputField;
		TimeElement.DataPath = TableName + "." + AttributeName;
		TimeElement.Title = Selection.Description;
		TimeElement.Width = 8;
		TimeElement.ChoiceButton = False;
		TimeElement.SpinButton = True;
		TimeElement.SetAction("OnChange", "Attachable_ChangeoverDurationTableAnyEquipmentSetupSettingTimeWhenChanging");
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInChangeoverTable(TableSetupOptions)

	SettingUpChangeover = InformationRegisters.ChangeoverDurationTime.SettingUpChangeover(WorkCenterType);
	TableChangeoverDuration.Load(SettingUpChangeover);
	
	NumberCurSettingOption = 0;
	NumberOfAdjustmentOptions = SetupOptionsInTable.Count();
	For Each CurrentSetupSettings In TableSetupOptions Do
		NewRow = ChangeoverDurationTable.Add();
		NewRow.FirstColumn = CurrentSetupSettings.Description;
		
		NumberCurSettingOption = NumberCurSettingOption + 1;
		
		NumberNextAdjustmentOption = 0;
		For Each NextSetupSettings In TableSetupOptions Do
			CommonPropsName = "SetupSettings" + Format(NumberNextAdjustmentOption, "NZ=0; NG=");
			NumberNextAdjustmentOption = NumberNextAdjustmentOption + 1;
			
			If CurrentSetupSettings.SetupSettings = NextSetupSettings.SetupSettings
				And ValueIsFilled(CurrentSetupSettings.SetupSettings) Then
				NewRow[CommonPropsName + "Available"] = False;
				NewRow[CommonPropsName + "OwnerSettingIndex"] = -1;
				Continue;
			EndIf; 
			
			TheStructureOfTheSearch = New Structure("CurrentSetupSettings,NextSetupSettings", 
								CurrentSetupSettings.SetupSettings, 
								NextSetupSettings.SetupSettings);
								
	  		StringsList = TableChangeoverDuration.FindRows(TheStructureOfTheSearch);
			If StringsList.Count() <> 0 Then
				ChangeoverData = StringsList[0];
				NewRow[CommonPropsName + "Time"]                 = ChangeoverData.ChangeoverTime;
				NewRow[CommonPropsName + "SettingIsInherited"] = ChangeoverData.SettingIsInherited;
				NewRow[CommonPropsName + "Priority"]             = ChangeoverData.Priority;
			EndIf;
			NewRow[CommonPropsName + "Available"] = True;
			
			NewRow[CommonPropsName + "OwnerSettingIndex"] = OwnerSettingIndex(
																				NewRow[CommonPropsName + "Priority"], 
																				NumberCurSettingOption - 1, 
																				NumberNextAdjustmentOption - 1,
																				NumberOfAdjustmentOptions);
			
		EndDo;
	EndDo;

	// Fill in the index settings
	NumberOfAdjustmentOptions = SetupOptionsInTable.Count();
	For NumberCurSettingOption = 1 To NumberOfAdjustmentOptions Do
		CurrentData = ChangeoverDurationTable[NumberCurSettingOption - 1];
		CurrentData["SetupSettings0SettingIndex"] = NumberCurSettingOption;
	EndDo; 
	CurrentData = ChangeoverDurationTable[0];
	For NumberNextAdjustmentOption = 2 To NumberOfAdjustmentOptions Do
		CommonPropsName = "SetupSettings" + Format(NumberNextAdjustmentOption-1, "NZ=0; NG=");
		CurrentData[CommonPropsName + "SettingIndex"] = NumberOfAdjustmentOptions + NumberNextAdjustmentOption - 1;
	EndDo; 
	
EndProcedure

&AtServer
Procedure AddConditionalAppearance(CommonPropsName)
	
	// Available
	ConditionalAppearanceElement = ConditionalAppearance.Items.Add(); 
	ConditionalAppearanceElement.Use = True;
	
	FilterDesignFeatures = ConditionalAppearanceElement.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("ChangeoverDurationTable." + CommonPropsName + "Available");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	DesignField               = ConditionalAppearanceElement.Fields.Items.Add(); 
	DesignField.Use = True;
	DesignField.Field          = New DataCompositionField("ChangeoverDurationTable" + CommonPropsName + "Time");
	
	AppearanceSetting = ConditionalAppearanceElement.Appearance.FindParameterValue(New DataCompositionParameter("ReadOnly")); 
	AppearanceSetting.Value      = True; 
	AppearanceSetting.Use = True;
	
	AppearanceSetting = ConditionalAppearanceElement.Appearance.FindParameterValue(New DataCompositionParameter("BackColor")); 
	AppearanceSetting.Value      = StyleColors.InaccessibleCellTextColor; 
	AppearanceSetting.Use = True;

	// SettingIsInherited
	ConditionalAppearanceElement = ConditionalAppearance.Items.Add(); 
	ConditionalAppearanceElement.Use = True;
	
	FilterDesignFeatures = ConditionalAppearanceElement.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("ChangeoverDurationTable." + CommonPropsName + "SettingIsInherited");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	FilterDesignFeatures = ConditionalAppearanceElement.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("ChangeoverDurationTable." + CommonPropsName + "SettingIndex");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = New DataCompositionField("OwnerSettingIndex");
	
	DesignField               = ConditionalAppearanceElement.Fields.Items.Add(); 
	DesignField.Use = True;
	DesignField.Field          = New DataCompositionField("ChangeoverDurationTable" + CommonPropsName + "Time");
	
	AppearanceSetting = ConditionalAppearanceElement.Appearance.FindParameterValue(New DataCompositionParameter("TextColor")); 
	AppearanceSetting.Value      = StyleColors.HelpText; 
	AppearanceSetting.Use = True;
	
	// Highlighting the color of the cell by which the changeover time in the active cell is determined.
	ConditionalAppearanceElement = ConditionalAppearance.Items.Add(); 
	ConditionalAppearanceElement.Use = True;
	
	FilterDesignFeatures = ConditionalAppearanceElement.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("ChangeoverDurationTable." + CommonPropsName + "SettingIndex");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = New DataCompositionField("OwnerSettingIndex");
	
	DesignField               = ConditionalAppearanceElement.Fields.Items.Add(); 
	DesignField.Use = True;
	DesignField.Field          = New DataCompositionField("ChangeoverDurationTable" + CommonPropsName + "Time");
	
	AppearanceSetting = ConditionalAppearanceElement.Appearance.FindParameterValue(New DataCompositionParameter("TextColor")); 
	AppearanceSetting.Value      = WebColors.DarkBlue; 
	AppearanceSetting.Use = True;
	
	AppearanceSetting = ConditionalAppearanceElement.Appearance.FindParameterValue(New DataCompositionParameter("Font")); 
	AppearanceSetting.Value      = New Font(,,True);
	AppearanceSetting.Use = True;
	
EndProcedure

&AtClient
Procedure UpdateChangeoverDuration(DurationOfChangeoverArray)

	TableChangeoverDuration.Clear();
	For Each CollectionItem In DurationOfChangeoverArray Do
		NewRow = TableChangeoverDuration.Add();
		FillPropertyValues(NewRow, CollectionItem);
	EndDo; 
	
	NumberCurSettingOption = 0;
	NumberOfAdjustmentOptions = SetupOptionsInTable.Count();
	For Each CurrentData In ChangeoverDurationTable Do
		
		CurrentSetupSettings = SetupOptionsInTable.Get(NumberCurSettingOption).Value;
		
		NumberCurSettingOption = NumberCurSettingOption + 1;
		
		NumberNextAdjustmentOption = 0;
		For Each ConsiderFollowingAdjustmentOption In SetupOptionsInTable Do
			CommonPropsName = "SetupSettings" + Format(NumberNextAdjustmentOption, "NZ=0; NG=");
			NextSetupSettings = SetupOptionsInTable.Get(NumberNextAdjustmentOption).Value;
			
			NumberNextAdjustmentOption = NumberNextAdjustmentOption + 1;
			
			If CurrentSetupSettings = NextSetupSettings And ValueIsFilled(CurrentSetupSettings) Then
				Continue;
			EndIf;
			
			TheStructureOfTheSearch = New Structure("CurrentSetupSettings,NextSetupSettings", 
								CurrentSetupSettings, 
								NextSetupSettings);
								
	  		StringsList = TableChangeoverDuration.FindRows(TheStructureOfTheSearch);
			If StringsList.Count() <> 0 Then
				ChangeoverData = StringsList[0];
				CurrentData[CommonPropsName + "Time"]                 = ChangeoverData.ChangeoverTime;
				CurrentData[CommonPropsName + "SettingIsInherited"] = ChangeoverData.SettingIsInherited;
				CurrentData[CommonPropsName + "Priority"]             = ChangeoverData.Priority;
			EndIf;
			
			CurrentData[CommonPropsName + "OwnerSettingIndex"] = OwnerSettingIndex(
																				CurrentData[CommonPropsName + "Priority"], 
																				NumberCurSettingOption - 1, 
																				NumberNextAdjustmentOption - 1,
																				NumberOfAdjustmentOptions);
			
		EndDo; 
		
	EndDo; 
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetColorDesignOfAdjustmentOptions()

	// Delete the old design
	ItemsToDelete_ = New Array;
	For Each AppearanceItem In ConditionalAppearance.Items Do
		If AppearanceItem.Presentation = "ColorOfDesign" Then
			ItemsToDelete_.Add(AppearanceItem);
		EndIf; 
	EndDo; 
	For Each AppearanceItem In ItemsToDelete_ Do
		ConditionalAppearance.Items.Delete(AppearanceItem);
	EndDo; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SetupOptions.ColorOfDesign,
	|	SetupOptions.Ref
	|FROM
	|	Catalog.SetupOptions AS SetupOptions
	|WHERE
	|	(SetupOptions.Owner = &WorkCenterType
	|			OR &WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef))";
	
	Query.SetParameter("WorkCenterType", WorkCenterType);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Storage = Selection.ColorOfDesign; // ValueStorage
		ObjectDesignColor = Storage.Get();
		If ObjectDesignColor = Undefined Then
			Continue;
		EndIf;
		
		ColorAdjustmentOption = ObjectDesignColor.ColorOfDesign;
		
		Item = ConditionalAppearance.Items.Add();
		Item.Presentation = "ColorOfDesign";
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListSetupOptions.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListSetupOptions.Ref");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Selection.Ref;

		Item.Appearance.SetParameterValue("BackColor", ColorAdjustmentOption);
		
	EndDo;

EndProcedure

&AtServerNoContext
Function ChangeoverTimeTableAtEndOfEditingOnServer(Val RowData, Val WorkCenterType)

	SaveRowDataToServer(RowData, WorkCenterType);
	
	// We will return the changeover setting to re-fill the table on the client
	TableChangeoverDuration = InformationRegisters.ChangeoverDurationTime.SettingUpChangeover(WorkCenterType);
	DurationOfChangeoverArray = New Array;
	For Each CollectionItem In TableChangeoverDuration Do
		ChangeoverData = New Structure;
		ChangeoverData.Insert("CurrentSetupSettings",   CollectionItem.CurrentSetupSettings);
		ChangeoverData.Insert("NextSetupSettings", CollectionItem.NextSetupSettings);
		ChangeoverData.Insert("ChangeoverTime",        CollectionItem.ChangeoverTime);
		ChangeoverData.Insert("SettingIsInherited",   CollectionItem.SettingIsInherited);
		ChangeoverData.Insert("Priority",               CollectionItem.Priority);
		DurationOfChangeoverArray.Add(ChangeoverData);
	EndDo;
	
	Return DurationOfChangeoverArray;
	
EndFunction

&AtServerNoContext
Procedure SaveRowDataToServer(Val RowData, Val WorkCenterType)

	For Each ChangeoverData In RowData Do
		InformationRegisters.ChangeoverDurationTime.SetChangeoverDuration(
				WorkCenterType,
				ChangeoverData.CurrentSetupSettings, 
				ChangeoverData.NextSetupSettings, 
				ChangeoverData.ChangeoverTime);
	EndDo; 

EndProcedure

&AtClientAtServerNoContext
Function OwnerSettingIndex(Priority, NumberCurSettingOption, NumberNextAdjustmentOption, NumberOfAdjustmentOptions)

	OwnerSettingIndex = -1;
	If Priority = 2 Then
		OwnerSettingIndex = NumberOfAdjustmentOptions + NumberNextAdjustmentOption;
	ElsIf Priority = 3 Then
		OwnerSettingIndex = NumberCurSettingOption + 1;
	ElsIf Priority = 4 Then
		OwnerSettingIndex = 1;
	EndIf; 
	
	Return OwnerSettingIndex;

EndFunction

&AtClient
Function IndexOfFieldByElementName(TagName)

	NameBeginning = StrFind(TagName, "SetupSettings") + StrLen("SetupSettings");
	NameEnding = StrFind(TagName, "Time");
	FieldIndex = Mid(TagName, NameBeginning, NameEnding - NameBeginning);

	Return FieldIndex;
	
EndFunction

#EndRegion

#EndRegion
