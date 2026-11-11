#Region Variables

&AtClient
Var RepeatCallBeforeRecording; // Used for non-modal questions before recording
&AtClient
Var IdleHandlerParameters;
&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(DISTINCT SeasonalGroupsOfBusinessRegions.Ref) AS RefsCount
	|FROM
	|	Catalog.SeasonalGroupsOfBusinessRegions AS SeasonalGroupsOfBusinessRegions";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.RefsCount <= 1 And SeasonalGroupsOfBusinessRegions.Count() = 0 Then
		SeasonalGroupsOfBusinessRegions.Add(PredefinedValue("Catalog.SeasonalGroupsOfBusinessRegions.OtherItems"));
	EndIf; 
	
	Periodicity = Constants.FrequencyOfSeasonalIndexEntry.Get();
	
	CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
	
	FactorChartType = Enums.ChartTypesOfIndicators.Line;
	
	If Parameters.ReadOnly Or Not AccessRight("Update", Metadata.InformationRegisters.SeasonalIndexes) Then
		ThisForm.ReadOnly = True;
	EndIf; 
	
	Items.SeasonalIndexesChange.Enabled = Not ThisForm.ReadOnly;
	Items.SeasonalIndexesCreate.Enabled = AccessRight("Insert", Metadata.Catalogs.SeasonalGroups);
	
	If TypeOf(Parameters.SeasonalGroups) = Type("Array") Then
	
		SeasonalGroups.LoadValues(Parameters.SeasonalGroups);
		
	ElsIf TypeOf(Parameters.SeasonalGroups) = Type("ValueList") Then
	
		SeasonalGroups.LoadValues(Parameters.SeasonalGroups.UnloadValues());
		
	ElsIf TypeOf(Parameters.SeasonalGroups) = Type("CatalogList.SeasonalGroups") Then
	
		SeasonalGroups.Add(Parameters.SeasonalGroups);
		
	EndIf; 
	
	Planning.CreatePeriodTable(ThisForm, "TimeIntervals");
	
	TablePeriods = TablePeriods();
	
	Planning.FillInPeriodTable(TablePeriods, 
		Periodicity, 
		Date("00010101"), 
		Date("00011231235959"), 
		Periodicity <> Enums.Periodicity.Week);
	
	If Periodicity = Enums.Periodicity.Week Then
	
		FoundRows = TablePeriods.FindRows(New Structure("StartDate", Date("00011231000000")));
		If FoundRows.Count() > 0 Then
		
			Period = FoundRows[0];
			Period.Title = NStr("vi = '31.12';
								|ru = '31.12';
								|en = '31.12'; fa = '31.12';
								|it = '31.12';
								|pl = '31.12';
								|tr = '31.12'");
		
		EndIf; 
	EndIf; 
	
	ValueToFormAttribute(TablePeriods,"TimeIntervals");
	
	OutputParameters = New Structure;
	OutputParameters.Insert("NameOfCrossTableProps", "SeasonalIndexes");
	OutputParameters.Insert("CrossTableFormElement", "SeasonalIndexes");
	OutputParameters.Insert("PeriodsTable", TablePeriods);
	OutputParameters.Insert("Periodicity", Periodicity);
	
	OutputParameters.Insert("GroupFields_", False);
	OutputParameters.Insert("HeaderOfDimensionField", NStr("vi = 'Kỳ kế hoạch';
															|ru = 'Периоды планирования';
															|en = 'Planning periods'; fa = 'دوره‌های برنامه‌ریزی';
															|it = 'Periodi di pianificazione';
															|pl = 'Okresy planowania';
															|tr = 'Planlama dönemleri'"));
	
	OutputParameters.Insert("Fields", New Array());
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", PrefixOfColumnSPropsCoefficient());
	FieldStructure.Insert("Title", "");
	FieldStructure.Insert("DeleteTableDetails", False);
	FieldStructure.Insert("CreateElement_", True);
	FieldStructure.Insert("ElementType", TMCommonUse.GetDescriptionOfNumberTypes(15, 3));
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemWidth", 6);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "Attachable_SeasonalCoefficientsWhenCoefficientChanges");
	FieldStructure.Insert("StructureOfActions", StructureOfActions);
	
	OutputParameters.Fields.Add(FieldStructure);
	
	Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
EndProcedure

// Returns:
// 	ValueTable - table periods with mandatory columns:
//    * Title - String - period title
//    * StartDate - Date - 
//    * EndDate - Date - 
&AtServer
Function TablePeriods()
	
	Return FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Periodicity) Then
	
		Cancel = True;
		ShowMessageBox(,NStr("vi = 'Chưa chỉ ra tùy chỉnh ""Định kỳ chỉ ra hệ số theo thời vụ"" trong phần hành Quản trị hệ thống - Bán hàng.';
							|ru = 'Не указана настройка ""Периодичность указания сезонных коэффициентов"" в разделе Администрирование - Продажи.';
							|en = 'The ""Periodicity of specification of seasonal indexes"" setting in section Settings - Sales is not specified.'; fa = 'The ""Periodicity of specification of seasonal indexes"" setting in section Settings - Sales is not specified.';
							|it = 'Non è indicata l''impostazione ""Periodicità di indicazione dei coefficienti stagionali"" nella sezione Amministrazione - Vendite.';
							|pl = 'Ustawienie ""Okresowość określania wskaźników sezonowych"" nie jest określone w sekcji Administrowanie - Sprzedaże.';
							|tr = 'Yönetim - Satışlar bölümündeki ""Belirtilen sezonsal katsayıların sıklığı"" ayarı belirtilmemiş.'"));
		
	Else
		
		FillAtServer();
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If RepeatCallBeforeRecording = True Then
		RepeatCallBeforeRecording = False;
		Return;
	EndIf; 
	
	If Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes,     NStr("vi = 'Lưu lại';
													|ru = 'Сохранить';
													|en = 'Save'; fa = 'ذخیره';
													|it = 'Salvare';
													|pl = 'Save';
													|tr = 'Sakla'"));
		Buttons.Add(DialogReturnCode.No,    NStr("vi = 'Không lưu lại';
												|ru = 'Не сохранять';
												|en = 'Do not save'; fa = 'Do not save';
												|it = 'Non salvare';
												|pl = 'Nie zapisuj';
												|tr = 'Kaydetme'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(Notification,
			NStr("vi = 'Đã thay đổi hệ số. Lưu lại thay đổi?';
				|ru = 'Коэффциенты были изменены. Сохранить изменения?';
				|en = 'Indexes were changed. Save the changes?'; fa = 'Indexes were changed. Save the changes?';
				|it = 'I coefficienti sono stati modificati. Salvare le modifiche?';
				|pl = 'Współczynniki zostały zmienione. Chcesz zapisać zmiany?';
				|tr = 'Katsayılar değiştirildi. Değişiklikler kaydedilsin mi?'"),
			Buttons);
		
		Cancel = True;
		RepeatCallBeforeRecording = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SeasonalGroupsOnChange(Item)
	
	If Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại và cập nhật';
												|ru = 'Записать и обновить';
												|en = 'Save and update'; fa = 'Save and update';
												|it = 'Salvare e aggiornare';
												|pl = 'Zapisz i zaktualizuj';
												|tr = 'Kaydet ve güncelle'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Cập nhật';
												|ru = 'Обновить';
												|en = 'Update'; fa = 'به‌روزرسانی';
												|it = 'Aggiornare';
												|pl = 'Update';
												|tr = 'Güncelle'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không cập nhật';
													|ru = 'Не обновлять';
													|en = 'Do not update'; fa = 'به‌روزرسانی نشود';
													|it = 'Non aggiornare';
													|pl = 'Nie aktualizuj';
													|tr = 'Güncelleme'"));
		
		Notification = New CallbackDescription("SeasonalGroupsOnChangeCompletion", ThisObject);
		ShowQueryBox(Notification,
			NStr("vi = 'Đã thay đổi hệ số. Ghi lại thay đổi và cập nhật?';
				|ru = 'Коэффциенты были изменены. Записать изменения и обновить?';
				|en = 'Coefficients were changed. Save the changes and update?'; fa = 'Coefficients were changed. Save the changes and update?';
				|it = 'I coefficienti sono stati modificati. Salvare le modifiche e aggiornare?';
				|pl = 'Współczynniki zostały zmienione. chcesz zapisać zmiany i zaktualizować?';
				|tr = 'Katsayılar değiştirildi. Değişiklikler kaydedilsin ve güncellensin mi?'"),
			Buttons);
		
	Else
	
		FillAtServer();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If Items.GroupPages.CurrentPage = Items.GroupSchedule Then
	
		GraphOnServer();
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure ChartTypeOnChange(Item)
	
	ChartTypeWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DataTypeOnChange(Item)
	
	GraphOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Schedule(Command)
	
	GraphOnServer();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	If Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Cập nhật';
												|ru = 'Обновить';
												|en = 'Update'; fa = 'به‌روزرسانی';
												|it = 'Aggiornare';
												|pl = 'Update';
												|tr = 'Güncelle'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không cập nhật';
													|ru = 'Не обновлять';
													|en = 'Do not update'; fa = 'به‌روزرسانی نشود';
													|it = 'Non aggiornare';
													|pl = 'Nie aktualizuj';
													|tr = 'Güncelleme'"));
		
		Notification = New CallbackDescription("RefreshCompletion", ThisObject);
		ShowQueryBox(Notification,
			NStr("vi = 'Đã thay đổi hệ số. Khi cập nhật, dữ liệu sẽ không được lưu lại. Cập nhật?';
				|ru = 'Коэффциенты были изменены. При обновлении данные не будут сохранены. Обновить?';
				|en = 'Coefficients were changed. Data will not be saved on updating. Update?'; fa = 'Coefficients were changed. Data will not be saved on updating. Update?';
				|it = 'I coefficienti sono stati modificati. Se si aggiorna i dati non verranno salvati. Aggiornare?';
				|pl = 'Współczynniki zostały zmienione. Podczas aktualizacji dane nie zostaną zapisane. Aktualizować?';
				|tr = 'Katsayılar değiştirildi. Veriler güncelleneceği için kaydedilmeyecek. Güncellensin mi?'"),
			Buttons);
		
	Else
	
		FillAtServer();
	
	EndIf; 
	
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteAtServer();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAtServer();
	Close();
	
EndProcedure

&AtClient
Procedure CalculateByStatistics(Command)
	
	If Items.SeasonalIndexes.SelectedRows.Count() = 0 Then
	
		ShowMessageBox(, NStr("vi = 'Cần tách chọn dòng để tính theo thống kê bán hàng.';
								|ru = 'Необходимо выделить строки для расчета по статистике продаж.';
								|en = 'Select lines for calculation by sales statistics.'; fa = 'Select lines for calculation by sales statistics.';
								|it = 'È necessario selezionare le righe per il conteggio secondo le statistiche delle vendite.';
								|pl = 'Konieczne jest wybranie wierszy do obliczania statystyk sprzedaży.';
								|tr = 'Satış istatistiğine göre hesaplama için satırların vurgulanmaları gerekmektedir.'"));
		Return;
	
	EndIf;
	
	Notification = New CallbackDescription("CalculateByStatisticsCompletion",ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Periodicity", Periodicity);
	FormParameters.Insert("CustomSettingsAddress", CustomSettingsAddress);
	
	OpenForm("InformationRegister.SeasonalIndexes.Form.FormOfPeriod",
		FormParameters,
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	ObjectForm = OpenForm("Catalog.SeasonalGroups.ObjectForm", 
		, 
		ThisForm, 
		UUID,
		,
		,
		, 
		FormWindowOpeningMode.LockOwnerWindow);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ObjectForm", ObjectForm);
	
	Notification = New CallbackDescription("CreateCompletion", ThisObject, NotificationParameters);
	
	ObjectForm.CallbackDescriptionOnClose = Notification;
	
EndProcedure

&AtClient
Procedure SelectByGroups(Command)
	
	If Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại và cập nhật';
												|ru = 'Записать и обновить';
												|en = 'Save and update'; fa = 'Save and update';
												|it = 'Salvare e aggiornare';
												|pl = 'Zapisz i zaktualizuj';
												|tr = 'Kaydet ve güncelle'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Cập nhật';
												|ru = 'Обновить';
												|en = 'Update'; fa = 'به‌روزرسانی';
												|it = 'Aggiornare';
												|pl = 'Update';
												|tr = 'Güncelle'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không cập nhật';
													|ru = 'Не обновлять';
													|en = 'Do not update'; fa = 'به‌روزرسانی نشود';
													|it = 'Non aggiornare';
													|pl = 'Nie aktualizuj';
													|tr = 'Güncelleme'"));
		
		Notification = New CallbackDescription("SelectByGroupsCompletion", ThisObject);
		ShowQueryBox(Notification,
			NStr("vi = 'Đã thay đổi hệ số. Ghi lại thay đổi và cập nhật?';
				|ru = 'Коэффциенты были изменены. Записать изменения и обновить?';
				|en = 'Coefficients were changed. Save the changes and update?'; fa = 'Coefficients were changed. Save the changes and update?';
				|it = 'I coefficienti sono stati modificati. Salvare le modifiche e aggiornare?';
				|pl = 'Współczynniki zostały zmienione. chcesz zapisać zmiany i zaktualizować?';
				|tr = 'Katsayılar değiştirildi. Değişiklikler kaydedilsin ve güncellensin mi?'"),
			Buttons);
		
	Else
		
		SeasonalGroups.Clear();
		
		For Each RowSelected In Items.SeasonalIndexes.SelectedRows Do
		
			TSRow = SeasonalIndexes.FindByID(RowSelected);
			If TSRow <> Undefined And ValueIsFilled(TSRow.ItemsGroup) Then
			
				SeasonalGroups.Add(TSRow.ItemsGroup);
			
			EndIf; 
		
		EndDo; 
		FillAtServer();
	
	EndIf; 
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeasonalIndexesSeasonalGroupOfBusinessRegion.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeasonalIndexes.SeasonalGroupOfBusinessRegion");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Catalog.SeasonalGroupsOfBusinessRegions.OtherItems");

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	UseBusinessRegions = GetFunctionalOption("UseBusinessRegions");
	
	Items.SeasonalGroupsOfBusinessRegions.Visible                    = UseBusinessRegions;
	Items.SeasonalIndexesSeasonalGroupOfBusinessRegion.Visible = UseBusinessRegions
	                                                                   And NumberOfBusinessRegionGroups > 1;
EndProcedure

&AtServer
Procedure GraphOnServer()
	
	ChartTypeName = TargetValueMonitoring.GetNameOfEnumerationValue(FactorChartType);
	Chart.ChartType = ChartType[ChartTypeName];
	Chart.SplineMode = ChartSplineMode.SmoothCurve;
	
	If DataType = 1 Then
		
		DataSource = GetAggregatedCoefficients();
	
	Else
	
		DataSource = SeasonalIndexes.Unload();
	
	EndIf; 
	
	DataSource.Columns.Insert(0, "Title");
	
	For Each Source In DataSource Do
		
		Source.Title = String(Source.ItemsGroup)
			+ ?(NumberOfBusinessRegionGroups > 1, 
				"; " + String(Source.SeasonalGroupOfBusinessRegion), "");
	
	EndDo; 
	
	DataSource.Columns.Delete("ItemsGroup");
	DataSource.Columns.Delete("SeasonalGroupOfBusinessRegion");
	
	Chart.DataSource = DataSource;
	
	For Each Series In Chart.Series Do
	
		Series.Marker = ChartMarkerType.None;
	
	EndDo; 
	
	For Each Point In Chart.Points Do
		
		IndexOf = Chart.Points.IndexOf(Point);
		TablePeriods = ThisForm.TimeIntervals; // See TablePeriods
		FoundRows = TablePeriods.FindRows(New Structure("Active_, ColumnNumber", True, IndexOf + 1));
		If FoundRows.Count() > 0 Then
		
			Point.Text = FoundRows[0].Title;
		
		EndIf; 
	
	EndDo;
	
	Chart.PlotArea.ValuesScale.ScaleLabelLocation = ChartScaleLabelLocation.Auto;
	
EndProcedure


// Returns:
// 	ValueTable - table of normalized coefficients:
//    * Title - String - 
&AtServer
Function GetAggregatedCoefficients()
	
	RatedCoefficients = SeasonalIndexes.Unload();
	
	NumberOfPeriods = ThisForm.TimeIntervals.FindRows(New Structure("Active_", True)).Count();
	
	For Each TSRow In RatedCoefficients Do
		
		CoefficientsSum = 0;
		
		For Each Period In ThisForm.TimeIntervals Do
			If Not Period.Active_ Then
				Continue;
			EndIf; 
			
			CoefficientsSum = CoefficientsSum + TSRow[PrefixOfColumnSPropsCoefficient() + Period.ColumnName];
		
		EndDo; 
		
		If CoefficientsSum = 0 Then
			Continue;
		EndIf; 
		
		AverageCoefficient = CoefficientsSum / NumberOfPeriods;
		
		For Each Period In ThisForm.TimeIntervals Do
			If Not Period.Active_ Then
				Continue;
			EndIf; 
			
			TSRow[PrefixOfColumnSPropsCoefficient() + Period.ColumnName] =  TSRow[PrefixOfColumnSPropsCoefficient() + Period.ColumnName] / AverageCoefficient;
		
		EndDo; 
	
	EndDo; 
	
	Return RatedCoefficients;
	
EndFunction

&AtClient
Procedure RefreshCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		FillAtServer();
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure SeasonalGroupsOnChangeCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		RecordAndUpdateOnServer();
		
	ElsIf Result = DialogReturnCode.No Then
	
		FillAtServer();
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure SelectByGroupsCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Or Result = DialogReturnCode.No Then
		
		SeasonalGroups.Clear();
		
		For Each RowSelected In Items.SeasonalIndexes.SelectedRows Do
		
			TSRow = SeasonalIndexes.FindByID(RowSelected);
			If TSRow <> Undefined And ValueIsFilled(TSRow.ItemsGroup) Then
			
				SeasonalGroups.Add(TSRow.ItemsGroup);
			
			EndIf; 
		
		EndDo;
	
	EndIf; 
	
	If Result = DialogReturnCode.Yes Then
	
		RecordAndUpdateOnServer();
		
	ElsIf Result = DialogReturnCode.No Then
	
		FillAtServer();
	
	EndIf; 
	
EndProcedure


// Parameters:
// 	Result - DialogReturnCode -
// 	NotificationParameters - Structure - Properties:
//   * ObjectForm - ClientApplicationForm - Required Details:
//     ** Object - DocumentObject - 
&AtClient
Procedure CreateCompletion(Result, NotificationParameters) Export
	
	ItemsGroup = NotificationParameters.ObjectForm.Object.Ref;
	
	If Not ValueIsFilled(ItemsGroup) Then
		Return;
	EndIf;
	
	If SeasonalGroups.Count() > 0 Then
	
		SeasonalGroups.Add(ItemsGroup);
	
	EndIf;
	
	If SeasonalGroupsOfBusinessRegions.Count()>0 Then 
		For Each SeasonalGroupOfBusinessRegions In SeasonalGroupsOfBusinessRegions Do
			NewRow = SeasonalIndexes.Add();
			NewRow.ItemsGroup = ItemsGroup;
			NewRow.SeasonalGroupOfBusinessRegion = SeasonalGroupOfBusinessRegions.Value;
		EndDo;
	Else
		NewRow = SeasonalIndexes.Add();
		NewRow.ItemsGroup = ItemsGroup;
		NewRow.SeasonalGroupOfBusinessRegion = PredefinedValue("Catalog.SeasonalGroupsOfBusinessRegions.OtherItems");
	EndIf;
	
	NotificationParameters.ObjectForm = Undefined;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		WriteAtServer();
		Close();
		
	ElsIf Result = DialogReturnCode.No Then
	
		Close();
		
	Else
		
		RepeatCallBeforeRecording = False;
	
	EndIf; 
	
EndProcedure

&AtServer
Procedure RecordAndUpdateOnServer()

	WriteAtServer();
	
	FillAtServer();
	
EndProcedure
 
&AtServer
Procedure FillAtServer()
	
	UseBusinessRegions = GetFunctionalOption("UseBusinessRegions");
	If Not UseBusinessRegions Then
	
		SeasonalGroupsOfBusinessRegions.Clear();
		SeasonalGroupsOfBusinessRegions.Add(Catalogs.SeasonalGroupsOfBusinessRegions.OtherItems);
	
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SeasonalGroups.Ref AS ItemsGroup,
	|	SeasonalGroupsOfBusinessRegions.Ref AS SeasonalGroupOfBusinessRegion,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN DATEADD(&BegOfYear, WEEK, SeasonalIndexes.PeriodNumber - 1)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN DATEADD(&BegOfYear, MONTH, SeasonalIndexes.PeriodNumber - 1)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN DATEADD(&BegOfYear, QUARTER, SeasonalIndexes.PeriodNumber - 1)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN DATEADD(&BegOfYear, YEAR, SeasonalIndexes.PeriodNumber - 1)
	|		ELSE DATEADD(&BegOfYear, DAY, SeasonalIndexes.PeriodNumber - 1)
	|	END AS Period,
	|	ISNULL(SeasonalIndexes.ZoomRatio, 0) AS ZoomRatio
	|FROM
	|	Catalog.SeasonalGroups AS SeasonalGroups
	|		LEFT JOIN Catalog.SeasonalGroupsOfBusinessRegions AS SeasonalGroupsOfBusinessRegions
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
	|		ON (SeasonalIndexes.Periodicity = &Periodicity)
	|			AND SeasonalGroups.Ref = SeasonalIndexes.ItemsGroup
	|			AND (SeasonalGroupsOfBusinessRegions.Ref = SeasonalIndexes.SeasonalGroupOfBusinessRegion)
	|WHERE
	|	1 = 1
	|	AND &AdditionalSelection_1
	|
	|ORDER BY
	|	SeasonalGroups.Description,
	|	SeasonalGroupsOfBusinessRegions.Description,
	|	Period
	|TOTALS BY
	|	ItemsGroup,
	|	SeasonalGroupOfBusinessRegion";
	
	FilterText1 = "";
	
	Query.SetParameter("BegOfYear", Date("00010101"));
	Query.SetParameter("Periodicity", Periodicity);
	
	CompleteSelectionOfSeasonalGroups = False;
	
	If SeasonalGroups.Count() > 0 Then
	
		FilterText1 = FilterText1 + " AND SeasonalGroups.Ref IN(&SeasonalGroups)";
		Query.SetParameter("SeasonalGroups", SeasonalGroups);
		CompleteSelectionOfSeasonalGroups = True;
	
	EndIf; 
	
	FillInSelectionOfSeasonalGroupsOfBusinessRegions = False;
	
	If SeasonalGroupsOfBusinessRegions.Count() > 0 Then
	
		FilterText1 = FilterText1 + "AND SeasonalGroupsOfBusinessRegions.Ref IN(&SeasonalGroupsOfBusinessRegions)";
		Query.SetParameter("SeasonalGroupsOfBusinessRegions", SeasonalGroupsOfBusinessRegions);
		FillInSelectionOfSeasonalGroupsOfBusinessRegions = True;
		
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "AND &AdditionalSelection_1", FilterText1);

	QueryResult = Query.Execute();

	SampleSeasonalGroup = QueryResult.Select(QueryResultIteration.ByGroups);

	SeasonalIndexes.Clear();
	SeasonalGroups.Clear();
	SeasonalGroupsOfBusinessRegions.Clear();
	
	NumberOfBusinessRegionGroups = 0;
	
	While SampleSeasonalGroup.Next() Do
		
		If CompleteSelectionOfSeasonalGroups Then
		
			SeasonalGroups.Add(SampleSeasonalGroup.ItemsGroup);
		
		EndIf;
		
		SampleSeasonalBusinessRegionGroup = SampleSeasonalGroup.Select(QueryResultIteration.ByGroups);
		While SampleSeasonalBusinessRegionGroup.Next() Do
			
			If FillInSelectionOfSeasonalGroupsOfBusinessRegions Then
				BusinessRegionGroup = SampleSeasonalBusinessRegionGroup.SeasonalGroupOfBusinessRegion;
				If SeasonalGroupsOfBusinessRegions.FindByValue(BusinessRegionGroup) = Undefined Then
					SeasonalGroupsOfBusinessRegions.Add(BusinessRegionGroup);
				EndIf; 
				
			EndIf;
			
			NumberOfBusinessRegionGroups = SampleSeasonalBusinessRegionGroup.Count();
			
			NewRow = SeasonalIndexes.Add();
			
			SelectionDetailRecords = SampleSeasonalBusinessRegionGroup.Select();
			
			FillPropertyValues(NewRow, SampleSeasonalBusinessRegionGroup);

			While SelectionDetailRecords.Next() Do
				Filter = New Structure("Active_, StartDate", True, SelectionDetailRecords.Period); 
				FoundRows = ThisForm.TimeIntervals.FindRows(Filter);
				If FoundRows.Count() > 0 Then
					
					NewRow[PrefixOfColumnSPropsCoefficient() + FoundRows[0].ColumnName] = SelectionDetailRecords.ZoomRatio;
					
				EndIf; 
			EndDo;
			
		EndDo; 
		
	EndDo;
	
	Modified = False;
	
	If Items.GroupPages.CurrentPage = Items.GroupSchedule Then
	
		GraphOnServer();
	
	EndIf; 
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure ChartTypeWhenChangedOnServer()
	
	If Not ValueIsFilled(FactorChartType) Then
		FactorChartType = Enums.ChartTypesOfIndicators.Line;
	EndIf;
	
	ChartTypeName = TargetValueMonitoring.GetNameOfEnumerationValue(FactorChartType);
	Chart.ChartType = ChartType[ChartTypeName];
	
EndProcedure

&AtServer
Procedure WriteAtServer(Cancel = False)
	
	RecordSet = InformationRegisters.SeasonalIndexes.CreateRecordSet();
	RecordSet.Filter.Periodicity.Set(Periodicity);
	
	RecordsetDay = InformationRegisters.SeasonalIndexes.CreateRecordSet();
	RecordsetDay.Filter.Periodicity.Set(Enums.Periodicity.Day);
	
	For Each TSRow In SeasonalIndexes Do
		
		If Not ValueIsFilled(TSRow.ItemsGroup) Then
			Continue;
		EndIf; 
		
		RecordSet.Filter.ItemsGroup.Set(TSRow.ItemsGroup);
		RecordSet.Filter.SeasonalGroupOfBusinessRegion.Set(TSRow.SeasonalGroupOfBusinessRegion);
		RecordSet.Clear();
		
		RecordsetDay.Filter.ItemsGroup.Set(TSRow.ItemsGroup);
		RecordsetDay.Filter.SeasonalGroupOfBusinessRegion.Set(TSRow.SeasonalGroupOfBusinessRegion);
		RecordsetDay.Clear();
		
		TablePeriods = ThisForm.TimeIntervals; // See TablePeriods
		
		For Each Period In TablePeriods Do
			If Not Period.Active_ Then
				Continue;
			EndIf;
			
			RsRecord = RecordSet.Add();
			RsRecord.Periodicity               = Periodicity;
			RsRecord.ItemsGroup              = TSRow.ItemsGroup;
			RsRecord.SeasonalGroupOfBusinessRegion = TSRow.SeasonalGroupOfBusinessRegion;
			RsRecord.PeriodNumber                = Period.ColumnNumber;
			RsRecord.ZoomRatio                 = TSRow[PrefixOfColumnSPropsCoefficient() + Period.ColumnName];
			
			PeriodNumber = DayOfYear(Period.StartDate);
			
			DaysCount = 1;
			If Periodicity = Enums.Periodicity.Month Then
				DaysCount = (Period.EndDate + 1 - Period.StartDate) / 86400;
			ElsIf Periodicity = Enums.Periodicity.Week Then
				DaysCount = 7;
				If PeriodNumber + DaysCount > 365 Then
				
					DaysCount = 365 - PeriodNumber + 1;
				
				EndIf; 
				
			EndIf;
			
			CoefficientToDistribution = TSRow[PrefixOfColumnSPropsCoefficient() + Period.ColumnName];
			
			For IndexOf = 1 To DaysCount Do
				
				ZoomRatio = CoefficientToDistribution / (DaysCount - IndexOf + 1);
				
				RsRecord = RecordsetDay.Add();
				RsRecord.Periodicity               = Enums.Periodicity.Day;
				RsRecord.ItemsGroup              = TSRow.ItemsGroup;
				RsRecord.SeasonalGroupOfBusinessRegion = TSRow.SeasonalGroupOfBusinessRegion;
				RsRecord.PeriodNumber                = PeriodNumber;
				RsRecord.ZoomRatio                 = ZoomRatio;
				
				PeriodNumber = PeriodNumber + 1;
				
				CoefficientToDistribution = CoefficientToDistribution - RsRecord.ZoomRatio;
			EndDo; 
			
		
		EndDo; 
		
		BeginTransaction();
		Try
			
			RecordSet.Write();
			RecordsetDay.Write();
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Bản ghi hệ số theo thời vụ';
								|ru = 'Запись сезонных коэффициентов';
								|en = 'Save seasonal indexes'; fa = 'Save seasonal indexes';
								|it = 'Salvare i coefficienti stagionali';
								|pl = 'Zapis wskaźników sezonowych';
								|tr = 'Mevsimsel katsayının kaydı'", CommonClientServer.DefaultLanguageCode()), 
			EventLogLevel.Error,
			,
			, 
			DetailErrorDescription(ErrorInfo()));
			
			ErrorText = NStr("vi = 'Không thể ghi lại hệ số theo nhóm: %ItemsGroup%';
							|ru = 'Не удалось записать коэффициенты по группе: %ItemsGroup%';
							|en = 'Cannot save factors for group: %ItemsGroup%'; fa = 'Cannot save factors for group: %ItemsGroup%';
							|it = 'Non è stato possibile salvare i coefficienti secondo il gruppo: %ItemsGroup%';
							|pl = 'Nie można zapisać współczynników grupy: %ItemsGroup%';
							|tr = 'Katsayılar şu gruba göre kaydedilemedi: %ItemsGroup%'");
			ErrorText = StrReplace(ErrorText , "%ItemsGroup%", String(TSRow.ItemsGroup));
			
			CommonClientServer.MessageToUser(ErrorText,,,"SeasonalIndexes", Cancel);
			
		EndTry; 
		
		
	EndDo; 
	
	If Not Cancel Then
	
		Modified = False;
	
	EndIf; 
	
	
EndProcedure

&AtClient
Procedure CalculateByStatisticsCompletion(Settings, AdditionalParameters) Export 
	
	If Settings <> Undefined Then
		
		Result = CalculateFromServerSalesStatistics(Settings);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("CalculateAlertBasedOnStatistics", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			Result, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateAlertBasedOnStatistics(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	RowsCount = GetCalculationResultOnServer(Result.ResultAddress);
	NotifyAboutEndOfCalculationOfSalesStatistics(Items.SeasonalIndexes.SelectedRows.Count(), 
		RowsCount);
		
EndProcedure

&AtClient
Procedure NotifyAboutEndOfCalculationOfSalesStatistics(NumberOfRowsTotal, RowsCount)

	Text = NStr("vi = 'Đã cập nhật: (%1) / (%2) dòng được tách chọn';
				|ru = 'Обновлено: (%1) из (%2) выделенных строк';
				|en = 'Updated: (%1) out of (%2) selected lines'; fa = 'Updated: (%1) out of (%2) selected lines';
				|it = 'Aggiornate: (%1) su (%2) righe selezionate';
				|pl = 'Zaktualizowano: (%1) z (%2) wybranych z wierszy';
				|tr = 'Güncellendi: (%1) ''den (%2) seçilmiş satır'");
	Text = StringFunctionsClientServer.SubstituteParametersToString(
		Text, 
		RowsCount, 
		NumberOfRowsTotal);
	ShowUserNotification(Text);

EndProcedure 

&AtServer
Function CalculateFromServerSalesStatistics(JobParameters)
	
	FilterSeasonalGroups = New ValueList;
	For Each String In Items.SeasonalIndexes.SelectedRows Do
		TSRow = SeasonalIndexes.FindByID(String);
		If ValueIsFilled(TSRow.ItemsGroup) Then
			FilterSeasonalGroups.Add(TSRow.ItemsGroup);
		EndIf; 
	EndDo; 
	
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Periodicity",           Periodicity);
	JobParameters.Insert("GeneralSettingsKey",       "InformationRegister.SeasonalIndexes");
	
	Settings = New Structure;
	Settings.Insert("FilterSeasonalGroups", FilterSeasonalGroups);
	Settings.Insert("UserSettings", GetFromTempStorage(CustomSettingsAddress));
	
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+JobParameters.UUID, 
		Settings);
	
	JobDescription = NStr("vi = 'Tính toán tỷ lệ theo mùa vụ từ thống kê bán hàng';
							|ru = 'Расчет сезонных коэффициентов по статистике продаж';
							|en = 'Calculation of seasonal indexes by sale statistics'; fa = 'Calculation of seasonal indexes by sale statistics';
							|it = 'Calcolo dei coefficienti stagionali secondo le statistiche delle vendite';
							|pl = 'Obliczanie wskaźników sezonowych dla statystyk sprzedaży';
							|tr = 'Satış istatistiklerine göre mevsimsel katsayıların muhasebesi'");
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.SeasonalIndexes.CalculateCoefficientsBasedOnSalesStatistics",
		JobParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtServer
Function GetCalculationResultOnServer(StorageAddress)
	
	TableOfCoefficients = GetFromTempStorage(StorageAddress);
	
	If TableOfCoefficients.Columns.Find("SeasonalGroupOfBusinessRegion") = Undefined Then
		
		TableOfCoefficients.Columns.Add("SeasonalGroupOfBusinessRegion");
		TableOfCoefficients.FillValues(Catalogs.SeasonalGroupsOfBusinessRegions.OtherItems, "SeasonalGroupOfBusinessRegion");
		
	EndIf;
	
	TableOfCoefficients.Sort("ItemsGroup, SeasonalGroupOfBusinessRegion, Period");
	
	ItemsGroup              = Undefined;
	SeasonalGroupOfBusinessRegion = Undefined;
	TSRow                    = Undefined;
	
	RowsCount = 0;
	
	For Each RowOfCoefficients In TableOfCoefficients Do
		
		If ItemsGroup <> RowOfCoefficients.ItemsGroup 
				Or SeasonalGroupOfBusinessRegion <> RowOfCoefficients.SeasonalGroupOfBusinessRegion Then
			
			RowsCount = RowsCount + 1;
			ItemsGroup              = RowOfCoefficients.ItemsGroup;
			SeasonalGroupOfBusinessRegion = RowOfCoefficients.SeasonalGroupOfBusinessRegion;
			
			FoundRows = SeasonalIndexes.FindRows(New Structure("ItemsGroup, SeasonalGroupOfBusinessRegion", 
			                                                         RowOfCoefficients.ItemsGroup, SeasonalGroupOfBusinessRegion));
			If FoundRows.Count() > 0 Then
				
				TSRow = FoundRows[0];
				For Each Period In ThisForm.TimeIntervals Do
					If Not Period.Active_ Then
						Continue;
					EndIf; 
					TSRow[PrefixOfColumnSPropsCoefficient()+Period.ColumnName] = 0;
				EndDo;
			Else
				TSRow = Undefined;
			EndIf; 
		EndIf;
		
		If TSRow = Undefined Then
			Continue;
		EndIf; 
		
		Filter = New Structure("Active_, StartDate", True, RowOfCoefficients.Period); 
		FoundRows = ThisForm.TimeIntervals.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			
			TSRow[PrefixOfColumnSPropsCoefficient()+FoundRows[0].ColumnName] = RowOfCoefficients.ZoomRatio;
			
		EndIf;
	EndDo; 
	
	Return RowsCount;
	
EndFunction

&AtClientAtServerNoContext
Function PrefixOfColumnSPropsCoefficient()
	
	Return "ZoomRatio_";
	
EndFunction

#EndRegion

