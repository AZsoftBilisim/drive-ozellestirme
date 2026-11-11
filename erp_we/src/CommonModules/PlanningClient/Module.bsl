////////////////////////////////////////////////////////////////////////////////
// General planning procedures and functions
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Procedure for changing the cancel flag for plan lines
//
// Parameters:
//  Form				 - ClientApplicationForm	 - The form of the document plan
//  Table				 - ValueTable				 - Table where the row cancellation flag is set
//  NameOfTableElement	 - String						 - Name of the table form element
//  ClosingNotification1	 - CallbackDescription			 - Notification that is executed after closing.
//
Procedure CancelPlanLines(Form, Table, NameOfTableElement, ClosingNotification1 = Undefined) Export 

	Items = Form.Items;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("NameOfTableElement", NameOfTableElement);
	AdditionalParameters.Insert("Table", Table);
	If ClosingNotification1 <> Undefined Then
		AdditionalParameters.Insert("ClosingNotification1", ClosingNotification1);
	EndIf; 
	
	If Form.Object.CrossTable Then
		
		If Items[NameOfTableElement].SelectedRows.Count() = 0 Then
			ShowUserNotification(NStr("vi = 'Chọn các dòng trong danh sách';
										|ru = 'Выделите строки в списке';
										|en = 'Select lines in the list'; fa = 'Select lines in the list';
										|it = 'Selezionare le righe nell''elenco';
										|pl = 'Zaznacz wierszy w liście';
										|tr = 'Listedeki satırı vurgulayınız'"));
			Return;
		EndIf;
		
		ActivePeriods = Form.TimeIntervals.FindRows(New Structure("Active_", True)); // See Planning.TablePeriods
		If ActivePeriods.Count() = 0  Then
			Return;
		EndIf;
		
		If ActivePeriods.Count() > 1  Then
			
			SelectedPeriod_1 = False;
			CurrentItem = Items[NameOfTableElement].CurrentItem; // FormField - 
			CurElementName = CurrentItem.Name;
			If StrFind(CurElementName, NameOfTableElement + "Count_") > 0
				Or StrFind(CurElementName, NameOfTableElement + "Comment_") > 0
				Or StrFind(CurElementName, NameOfTableElement + "Price_") > 0
				Or StrFind(CurElementName, NameOfTableElement + "Sum_") > 0 Then
				SelectedPeriod_1 = True;
			EndIf;
			
			If SelectedPeriod_1 Then
				For Each Period In ActivePeriods Do
					If CurElementName = NameOfTableElement + "Count_"+Period.ColumnName
						Or CurElementName = NameOfTableElement + "PictureComment_"+Period.ColumnName
						Or CurElementName = NameOfTableElement + "Price_"+Period.ColumnName
						Or CurElementName = NameOfTableElement + "Sum_"+Period.ColumnName Then
						Break;
					EndIf;
				EndDo;
			Else
				Period = ActivePeriods[0];
			EndIf; 
			
			If Items[NameOfTableElement].CurrentData["Canceled_"+Period.ColumnName] Then
				QueryText = NStr("vi = 'Bỏ dấu hủy ô hàng dự tính trong toàn kỳ?';
								|ru = 'Снять пометку отмены ячеек плана для всех периодов?';
								|en = 'Clear a cancellation mark for plan cells for all periods?'; fa = 'Clear a cancellation mark for plan cells for all periods?';
								|it = 'Rimuovere il contrassegno di annullamento delle celle del piano per tutti i periodi?';
								|pl = 'Usunąć zaznaczenie anulowania komórek planu dla wszystkich okresów?';
								|tr = 'Tüm dönemler için hücre planı onay kutusu iptali temizlensin mi?'");
			Else
				QueryText = NStr("vi = 'Đặt dấu hủy ô hàng trong sơ đồ trong toàn kỳ?';
								|ru = 'Установить пометку отмены ячеек плана для всех периодов?';
								|en = 'Set a mark of plan cell cancellation for all periods?'; fa = 'Set a mark of plan cell cancellation for all periods?';
								|it = 'Impostare il contrassegno di annullamento delle celle del piano per tutti i periodi?';
								|pl = 'Ustawić zaznaczenie anulowania komórek planu dla wszystkich okresów?';
								|tr = 'Tüm dönemler için hücre planı onay kutusu iptali seçilsin mi?'");
			EndIf; 
			
			AdditionalParameters.Insert("ColumnName", Period.ColumnName);
			AdditionalParameters.Insert("Canceled",   Not Items[NameOfTableElement].CurrentData["Canceled_"+Period.ColumnName]);
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes,     NStr("vi = 'Có, đối với tất cả';
														|ru = 'Да, для всех';
														|en = 'Yes, for all'; fa = 'Yes, for all';
														|it = 'Si, per tutti';
														|pl = 'Tak, dla wszystkich';
														|tr = 'Evet, tümü için'"));
			Buttons.Add(DialogReturnCode.No,    NStr("vi = 'Chỉ';
													|ru = 'Только';
													|en = 'Only'; fa = 'Only';
													|it = 'Solo';
													|pl = 'Only';
													|tr = 'Sadece'") + " " + Period.Title);
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Anuluj';
														|tr = 'İptal'"));
			
			Notification = New CallbackDescription("CancelPlanLinesCompletion", ThisObject, AdditionalParameters);
			
			ShowQueryBox(Notification, QueryText, Buttons);
		Else
		
			Period = ActivePeriods[0];
			
			AdditionalParameters.Insert("ColumnName", Period.ColumnName);
			AdditionalParameters.Insert("Canceled",   Not Items[NameOfTableElement].CurrentData["Canceled_"+Period.ColumnName]);
			CancelPlanLinesCompletion(DialogReturnCode.No, AdditionalParameters);
		
		EndIf; 
	Else
		
		If Items[NameOfTableElement].SelectedRows.Count() = 0 Then
			ShowUserNotification(NStr("vi = 'Chọn các dòng trong danh sách';
										|ru = 'Выделите строки в списке';
										|en = 'Select lines in the list'; fa = 'Select lines in the list';
										|it = 'Selezionare le righe nell''elenco';
										|pl = 'Zaznacz wierszy w liście';
										|tr = 'Listedeki satırı vurgulayınız'"));
			Return;
		EndIf;
		
		AdditionalParameters.Insert("Canceled", Not Items[NameOfTableElement].CurrentData.Canceled);
		CancelPlanLinesCompletion(DialogReturnCode.Yes, AdditionalParameters);
		
	EndIf;

EndProcedure

// Procedure-Show a question when changing the scenario
//
// Parameters:
//  Form				 - ClientApplicationForm				 - The form of the document plan
//  ClosingNotification1	 - CallbackDescription			 - Notification that is executed after closing.
Procedure ShowQuestionWhenScriptChanges(Form, ClosingNotification1 = Undefined) Export 
	
	If ValueIsFilled(Form["DetailsBeforeChange"].Scenario) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		If ClosingNotification1 <> Undefined Then
			AdditionalParameters.Insert("ClosingNotification1", ClosingNotification1);
		EndIf; 
		
		Notification = New CallbackDescription(
			"ShowQuestionWhenScriptChangesCompletion", 
			ThisObject, 
			AdditionalParameters);
		
		QueryText = NStr("vi = 'Đã thay đổi kịch bản. Cần cập nhật quy tắc điền. Cập nhật?';
						|ru = 'Сценарий изменен. Правило заполнения будет обновлено. Обновить?';
						|en = 'Scenario is changed. Filling rule will be updated. Update?'; fa = 'Scenario is changed. Filling rule will be updated. Update?';
						|it = 'Scenario cambiato. La regola di compilazione verrà aggiornata. Aggiornare?';
						|pl = 'Scenariusz został zmieniony. Reguła wypełnienia będzie aktualizowana. Zaktualizować?';
						|tr = 'Senaryo düzenlendi. Doldurma kuralı güncellenecektir. Güncellensin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Cập nhật';
												|ru = 'Обновить';
												|en = 'Update'; fa = 'به‌روزرسانی';
												|it = 'Aggiornare';
												|pl = 'Update';
												|tr = 'Güncelle'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ việc thay đổi kịch bản';
												|ru = 'Отменить изменение сценария';
												|en = 'Cancel scenario change'; fa = 'Cancel scenario change';
												|it = 'Annullare la modifica di scenario';
												|pl = 'Anuluj zmianę scenariusza';
												|tr = 'Senaryo değişikliklerini iptal et'"));
		ShowQueryBox(Notification, QueryText, Buttons);
		
		
	ElsIf ClosingNotification1 <> Undefined Then
		RunCallback(ClosingNotification1, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

// Procedure-Show a question when changing the plan view
//
// Parameters:
//  Form				 - ClientApplicationForm				 - The form of the document plan
//  ClosingNotification1	 - CallbackDescription			 - Notification that is executed after closing.
Procedure ShowQuestionWhenChangingPlanView(Form, ClosingNotification1 = Undefined) Export 
	
	If ValueIsFilled(Form["DetailsBeforeChange"].Scenario) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		If ClosingNotification1 <> Undefined Then
			AdditionalParameters.Insert("ClosingNotification1", ClosingNotification1);
		EndIf; 
		
		Notification = New CallbackDescription(
			"ShowQuestionWhenChangingPlanViewCompletion", 
			ThisObject, 
			AdditionalParameters);
		
		QueryText = NStr("vi = 'Đã thay đổi dạng kế hoạch. Sẽ cập nhật quy tắc điền. Cập nhật?';
						|ru = 'Вид плана изменен. Правило заполнения будет обновлено. Обновить?';
						|en = 'Plan profile is changed. Filling rule will be updated. Update?'; fa = 'Plan profile is changed. Filling rule will be updated. Update?';
						|it = 'Tipo di piano cambiato. La regola di compilazione verrà aggiornata. Aggiornare?';
						|pl = 'Rodzaj planu został zmieniony. Reguła wypełnienia będzie aktualizowana. Zaktualizować?';
						|tr = 'Plan profili düzenlendi. Doldurma kuralı güncellenecek. Güncellensin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Cập nhật';
												|ru = 'Обновить';
												|en = 'Update'; fa = 'به‌روزرسانی';
												|it = 'Aggiornare';
												|pl = 'Update';
												|tr = 'Güncelle'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ việc thay đổi dạng kế hoạch';
												|ru = 'Отменить изменение вида плана';
												|en = 'Cancel plan profile change'; fa = 'Cancel plan profile change';
												|it = 'Annullare modifica del tipo di piano';
												|pl = 'Anuluj zmianę rodzaju planu';
												|tr = 'Plan profili değişikliklerini iptal et'"));
		ShowQueryBox(Notification, QueryText, Buttons);
		
		
	ElsIf ClosingNotification1 <> Undefined Then
		RunCallback(ClosingNotification1, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

// Procedure-Change the formula to a percentage
//
// Parameters:
//  Form				 - ClientApplicationForm	 - The form of the document plan
//  Table				 - ValueTable				 - Table where the formula is set
//  NameOfTableElement	 - String						 - Name of the table form element
//  ClosingNotification1	 - CallbackDescription			 - Notification that is executed after closing.
//
Procedure ChangeFormulaToPercentage(Form, Table, NameOfTableElement, ClosingNotification1 = Undefined) Export 

	Items = Form.Items;
	SelectedRows = Items[NameOfTableElement].SelectedRows;
	
	If SelectedRows.Count() = 0  Then
	
		ShowMessageBox(, NStr("vi = 'Cần chọn dòng trong danh sách!';
								|ru = 'Необходимо выделить строки в списке!';
								|en = 'Select lines in the list.'; fa = 'Select lines in the list.';
								|it = 'È necessario evidenziare le righe nell''elenco!';
								|pl = 'Należy wydzielić wierszy w liście!';
								|tr = 'Listedeki satırları belirtmeniz gerekmektedir!'"));
		Return;
	
	EndIf; 
	
	ActivePeriods = Form.TimeIntervals.FindRows(New Structure("Active_", True)); // See Planning.TablePeriods
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("NameOfTableElement", NameOfTableElement);
	AdditionalParameters.Insert("Table", Table);
	If ClosingNotification1 <> Undefined Then
		AdditionalParameters.Insert("ClosingNotification1", ClosingNotification1);
	EndIf; 
	
	If Form.Object.CrossTable And ActivePeriods.Count() > 1 Then
		
		CurrentItem = Items[NameOfTableElement].CurrentItem; // FormField - 
		CurElementName = CurrentItem.Name;
		
		If StrFind(CurElementName, NameOfTableElement + "Count_") = 0 Then
			Period = ActivePeriods[0];
		Else
			For Each Period In ActivePeriods Do
				If CurElementName = NameOfTableElement + "Count_"+Period.ColumnName Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		 
		QueryText = NStr("vi = 'Đặt công thức đối với tất cả các kỳ?';
						|ru = 'Установить формулу для всех периодов?';
						|en = 'Set the formula for all periods?'; fa = 'Set the formula for all periods?';
						|it = 'Impostare la formula per tutti i periodi?';
						|pl = 'Ustawić ""ТаблицаПериодов"" dla wszystkich okresów?';
						|tr = 'Formül tüm dönemler için kurulsun mu?'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes,     NStr("vi = 'Có, đối với tất cả';
													|ru = 'Да, для всех';
													|en = 'Yes, for all'; fa = 'Yes, for all';
													|it = 'Si, per tutti';
													|pl = 'Tak, dla wszystkich';
													|tr = 'Evet, tümü için'"));
		Buttons.Add(DialogReturnCode.No,    NStr("vi = 'Chỉ';
												|ru = 'Только';
												|en = 'Only'; fa = 'Only';
												|it = 'Solo';
												|pl = 'Only';
												|tr = 'Sadece'") + " " + Period.Title);
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		AdditionalParameters.Insert("ColumnName",Period.ColumnName);
		
		Notification = New CallbackDescription("EnterPercentageAndChangeFormula", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Notification, QueryText, Buttons);
		
	ElsIf Form.Object.CrossTable And ActivePeriods.Count() = 1 Then
		
		Period = ActivePeriods[0];
		AdditionalParameters.Insert("ColumnName",Period.ColumnName);
		EnterPercentageAndChangeFormula(DialogReturnCode.No, AdditionalParameters);
		
	Else
		
		AdditionalParameters.Insert(
			"ColumnName",
			?(Table[0].Property("NumberOfPackages"), "NumberOfPackages", "Count"));
		
		EnterPercentageAndChangeFormula(DialogReturnCode.No, AdditionalParameters);
		
	EndIf; 

EndProcedure

// Procedure-Round the formula
//
// Parameters:
//  Form				 - ClientApplicationForm - The form of the document plan
//  Table				 - FormDataCollection		  - Table where the formula is set
//  NameOfTableElement	 - String					  - Name of the table form element
//  ClosingNotification1	 - CallbackDescription		  - Notification that is executed after closing.
//
Procedure RoundUpFormula(Form, Table, NameOfTableElement, ClosingNotification1 = Undefined) Export 

	Items = Form.Items;
	SelectedRows = Items[NameOfTableElement].SelectedRows;
	
	If SelectedRows.Count() = 0  Then
	
		ShowMessageBox(, NStr("vi = 'Cần chọn dòng trong danh sách!';
								|ru = 'Необходимо выделить строки в списке!';
								|en = 'Select lines in the list.'; fa = 'Select lines in the list.';
								|it = 'È necessario evidenziare le righe nell''elenco!';
								|pl = 'Należy wydzielić wierszy w liście!';
								|tr = 'Listedeki satırları belirtmeniz gerekmektedir!'"));
		Return;
	
	EndIf; 
	
	ActivePeriods = Form.TimeIntervals.FindRows(New Structure("Active_", True)); // See Planning.TablePeriods
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("NameOfTableElement", NameOfTableElement);
	AdditionalParameters.Insert("Table", Table);
	If ClosingNotification1 <> Undefined Then
		AdditionalParameters.Insert("ClosingNotification1", ClosingNotification1);
	EndIf; 
	
	If Form.Object.CrossTable And ActivePeriods.Count() > 1 Then
	
		CurrentItem = Items[NameOfTableElement].CurrentItem; // FormField - 
		CurElementName = CurrentItem.Name;
		
		If StrFind(CurElementName, NameOfTableElement + "Count_") = 0 Then
			Period = ActivePeriods[0];
		Else
			For Each Period In ActivePeriods Do
				If CurElementName = NameOfTableElement + "Count_"+Period.ColumnName Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		 
		QueryText = NStr("vi = 'Đặt công thức đối với tất cả các kỳ?';
						|ru = 'Установить формулу для всех периодов?';
						|en = 'Set the formula for all periods?'; fa = 'Set the formula for all periods?';
						|it = 'Impostare la formula per tutti i periodi?';
						|pl = 'Ustawić ""ТаблицаПериодов"" dla wszystkich okresów?';
						|tr = 'Formül tüm dönemler için kurulsun mu?'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes,     NStr("vi = 'Có, đối với tất cả';
													|ru = 'Да, для всех';
													|en = 'Yes, for all'; fa = 'Yes, for all';
													|it = 'Si, per tutti';
													|pl = 'Tak, dla wszystkich';
													|tr = 'Evet, tümü için'"));
		Buttons.Add(DialogReturnCode.No,    NStr("vi = 'Chỉ';
												|ru = 'Только';
												|en = 'Only'; fa = 'Only';
												|it = 'Solo';
												|pl = 'Only';
												|tr = 'Sadece'") + " " + Period.Title);
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		AdditionalParameters.Insert("ColumnName",Period.ColumnName);
		
		Notification = New CallbackDescription("SelectRoundingAccuracyChangeFormula", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Notification, QueryText, Buttons);
		
	ElsIf Form.Object.CrossTable And ActivePeriods.Count() = 1 Then
		
		Period = ActivePeriods[0];
		AdditionalParameters.Insert("ColumnName",Period.ColumnName);
		SelectRoundingAccuracyChangeFormula(DialogReturnCode.No, AdditionalParameters);
		
	Else
		
		AdditionalParameters.Insert(
			"ColumnName",
			?(Table[0].Property("NumberOfPackages"), "NumberOfPackages", "Count"));
		
		SelectRoundingAccuracyChangeFormula(DialogReturnCode.No, AdditionalParameters);
		
	EndIf; 

EndProcedure

// Procedure When changing the period of the plan
//
// Parameters:
//  Form				 - ClientApplicationForm	 - The form of the document plan:
//    * Object - DocumentObject.PurchasePlan - 
// 	          - DocumentObject.PlanOfGoodsStock -
// 	          - DocumentObject.SalesPlan -
// 	          - DocumentObject.SalesPlanByCategories -
// 	          - DocumentObject.ProductionPlan -
// 	          - DocumentObject.AssemblyDisassemblyPlan -
//  NameOfCrossTable		 - String						 - Name of the table form element
//  InterfaceUpdateAlert	 - CallbackDescription			 - Notification that is executed after closing.
Procedure WhenChangingPlanPeriod(Form, Val NameOfCrossTable, InterfaceUpdateAlert) Export 
	
	Object = Form.Object;
	RequiresRecalculationOfEndOfPeriod = TypeOf(Object.Ref) = Type("DocumentRef.PlanOfGoodsStock");
	CurrentSessionDate = CommonClient.SessionDate();
	PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod, Object.PeriodEnding, CurrentSessionDate, , RequiresRecalculationOfEndOfPeriod);
	
	NumberOfPeriodsExceeded = False;
	
	If Object.Periodicity = PredefinedValue("Enum.Periodicity.Year")
		Or Object.Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		If Object.PeriodEnding > AddMonth(Object.BeginOfPeriod, 120) Then // 10 years old
			NumberOfPeriodsExceeded = True;
			StringPeriod = NStr("vi = '10 năm';
								|ru = '10 лет';
								|en = '10 years'; fa = '10 سال';
								|it = '10 anni';
								|pl = '10 lat';
								|tr = '10 yıl'");
		EndIf;
	ElsIf Object.Periodicity = PredefinedValue("Enum.Periodicity.Quarter")
		Or Object.Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		If Object.PeriodEnding > AddMonth(Object.BeginOfPeriod, 60) Then // 5 years old
			NumberOfPeriodsExceeded = True;
			StringPeriod = NStr("vi = '5 năm';
								|ru = '5 лет';
								|en = '5 years'; fa = '5 سال';
								|it = '5 anni';
								|pl = '5 lat';
								|tr = '5 yıl'");
		EndIf;
	ElsIf Object.Periodicity = PredefinedValue("Enum.Periodicity.TenDays")
		Or Object.Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		If Object.PeriodEnding > Object.BeginOfPeriod + 86400 * 365 * 2 Then // 2 years
			NumberOfPeriodsExceeded = True;
			StringPeriod = NStr("vi = '2 năm';
								|ru = '2 года';
								|en = '2 years'; fa = '2 سال';
								|it = '2 anni';
								|pl = '2 lata';
								|tr = '2 yıl'");
		EndIf;
	ElsIf Object.Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		If Object.PeriodEnding > Object.BeginOfPeriod + 86400 * 365 Then // 1 year
			NumberOfPeriodsExceeded = True;
			StringPeriod = NStr("vi = '1 năm';
								|ru = '1 год';
								|en = '1 year'; fa = '1 سال';
								|it = '1 anno';
								|pl = '1 rok';
								|tr = '1 yıl'");
		EndIf;
	EndIf;
	
	If NumberOfPeriodsExceeded Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Продолжить';
												|pl = 'Continue';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ việc thay đổi kỳ';
												|ru = 'Отменить изменение периода';
												|en = 'Cancel period change'; fa = 'Cancel period change';
												|it = 'Annullare la modifica del periodo';
												|pl = 'Anuluj zmianę okresu';
												|tr = 'Dönem değişikliklerini iptal et'"));
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã vượt quá số lượng kỳ khuyến cáo (%1).
			|Điều này có thể làm hệ thống chạy chậm.
			|Tiếp tục?';
			|ru = 'Превышено рекомендуемое количество периодов (%1).
			|Это может замедлить работу системы.
			|Продолжить?';
			|en = 'You have exceeded the recommended number of periods (%1).
			|It might slow down the system operation.
			|Continue?'; fa = 'You have exceeded the recommended number of periods (%1).
			|It might slow down the system operation.
			|Continue?';
			|it = 'Превышено рекомендуемое количество периодов (%1).
			|Это может замедлить работу системы.
			|Продолжить?';
			|pl = 'You have exceeded the recommended number of periods (%1).
			|It might slow down the system operation.
			|Continue?';
			|tr = 'Önerilen dönem miktarı aşıldı (%1).
			|Bu sistem işini yavaşlatabilir .
			|Devam edilsin mi?'"), StringPeriod);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("InterfaceUpdateAlert", InterfaceUpdateAlert);
		Notification = New CallbackDescription("WhenChangingPlanPeriodCompletion", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Notification, QueryText, Buttons);
		Return;
	EndIf;
	
	If PlanningClientServer.YouNeedToUpdateInterface(Object, Form, "DetailsBeforeChange") Then
		
		CrossTable = Form[NameOfCrossTable];
		If Object.CrossTable
			And CrossTable.Count() > 0
			And Form.TimeIntervals.FindRows(New Structure("Active_", True)).Count() > 0 Then
			AskAQuestion = False;
			
			If Form["DetailsBeforeChange"].BeginOfPeriod <> Object.BeginOfPeriod 
				And Object.BeginOfPeriod > Form["DetailsBeforeChange"].BeginOfPeriod Then
				AskAQuestion = True;
			EndIf; 
			
			If Form["DetailsBeforeChange"].PeriodEnding <> Object.PeriodEnding 
				And Object.PeriodEnding < Form["DetailsBeforeChange"].PeriodEnding Then
				AskAQuestion = True;
			EndIf;
			
			If AskAQuestion Then
				Buttons = New ValueList;
				Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa kỳ';
														|ru = 'Удалить периоды';
														|en = 'Remove periods'; fa = 'Remove periods';
														|it = 'Eliminare periodi';
														|pl = 'Usuń okresy';
														|tr = 'Dönemleri sil'"));
				Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ việc thay đổi kỳ';
														|ru = 'Отменить изменение периода';
														|en = 'Cancel period change'; fa = 'Cancel period change';
														|it = 'Annullare la modifica del periodo';
														|pl = 'Anuluj zmianę okresu';
														|tr = 'Dönem değişikliklerini iptal et'"));
				QueryText = NStr("vi = 'Thay đổi kỳ kế hoạch sẽ làm xóa dữ liệu của nhiều kỳ. Xóa các kỳ?';
								|ru = 'Изменение периода плана приведет к удалению данных в некоторых периодах. Удалить периоды?';
								|en = 'Plan period change will lead to data deletion in some periods. Delete the periods?'; fa = 'Plan period change will lead to data deletion in some periods. Delete the periods?';
								|it = 'La modifica del periodo del piano causerà l''eliminazione dei dati in alcuni periodi. Eliminare i periodi?';
								|pl = 'Zmiana okresu planu spowoduje usunięcie danych w niektórych okresach. Usunąć okresy?';
								|tr = 'Plan döneminin değiştirilmesi, bazı dönem verilerinin silinmesine sebep olacak. Dönemler silinsin mi?'");
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("Form", Form);
				AdditionalParameters.Insert("InterfaceUpdateAlert", InterfaceUpdateAlert);
				Notification = New CallbackDescription("WhenChangingPlanPeriodCompletion", ThisObject, AdditionalParameters);
				
				ShowQueryBox(Notification, QueryText, Buttons);
				Return;
				
			EndIf;
			
		EndIf;
		
		RunCallback(InterfaceUpdateAlert);
		
	EndIf;
	
EndProcedure

// Calculation using the formula
//
// Parameters:
//  SourceFormula	 - String					 - Value of the original formula
//  CurrentData	 - FormDataCollectionItem	 - Value of the current data in the table part
//  TimeIntervals			 - FormDataCollection			 - Period values
//  Period			 - FormDataCollectionItem	 - Current period value from the period table
//  Presentation	 - String						 - The value of a custom representation of the formula.
//  ServerCall_ - Boolean
// 
// Returns:
//  Structure - Returns a structure with new formula representation parameters.
//
Function CalculateByFormula(Val SourceFormula, Val CurrentData, Val TimeIntervals, Val Period, Val Presentation = Undefined, ServerCall_ = False) Export
	
	Calculation_Formula = SourceFormula;
	OutputIntermediateCalculations = False;
	Postfix = Undefined;
	
	Parameters = New Structure();
	Parameters.Insert("Period", Period);
	Parameters.Insert("TimeIntervals", TimeIntervals);
	Parameters.Insert("CurrentData", CurrentData);
	
	If Period <> Undefined Then
		Postfix = Period.ColumnName;
	EndIf;
	
	ArrayOfOperands = PlanningClientServer.OperandsOfTextFormula(Calculation_Formula);
	
	For Each Operand In ArrayOfOperands Do
		
		If Postfix <> Undefined Then
			OperandName = Operand + "_" + Postfix;
		Else
			OperandName = Operand;
		EndIf;
		
		If Not CurrentData.Property(OperandName) Then
			Continue;
		EndIf;
		
		OperandValue = CurrentData[OperandName];
		If Not OutputIntermediateCalculations Then
			OutputIntermediateCalculations = Not IsBlankString(StrReplace(Calculation_Formula, "["+Operand+"]", ""));
		EndIf; 
		Calculation_Formula = StrReplace(Calculation_Formula, "["+Operand+"]", Format(OperandValue, "NDS=.; NZ=0; NG=0"));
		
	EndDo;
	
	Calculation_Formula = PlanningClientServer.AddParametersToFunctions(Calculation_Formula, "Parameters");
	
	Try
		CalculationResult = Format(Eval(Calculation_Formula),"ND=15; NFD=3; NZ=0");
	Except
		CalculationResult = 0;
	EndTry;
	
	Calculation_Formula = PlanningClientServer.RemoveParametersInFunctions(Calculation_Formula, "Parameters");
	
	If ValueIsFilled(SourceFormula) And SourceFormula <> PlanningClientServer.TextForSettingNewFormula() Then
		Calculation = SourceFormula + ?(OutputIntermediateCalculations, " = " + Calculation_Formula, "") + " = " + CalculationResult;
	Else
		Calculation = PlanningClientServer.TextForSettingNewFormula();
	EndIf;
	
	If SourceFormula <> PlanningClientServer.TextForSettingNewFormula() Then
		Presentation = ?(ValueIsFilled(Presentation),Presentation,SourceFormula);
	Else
		Presentation = "";
	EndIf;
	
	Return New Structure("Calculation,Result,Presentation", Calculation,CalculationResult,Presentation);

EndFunction

// Generate a transcript.
// 
// Parameters:
//  TSRow - FormDataCollectionItem -
//  PathToDecryption - String
// 
// Returns:
//  String, FormattedString - Generate A Decryption
Function GenerateDecryption(TSRow, PathToDecryption = "Details") Export
	
	If Not ValueIsFilled(TSRow[PathToDecryption]) Then
		Return "";
	EndIf;
	
	If TSRow = Undefined Then
		Return NStr("vi = 'Chưa chọn dòng';
					|ru = 'Строка не выбрана';
					|en = 'Line is not selected'; fa = 'Line is not selected';
					|it = 'Nessuna riga selezionata';
					|pl = 'Nie wybrano wiersza';
					|tr = 'Satır seçilmedi'");
	ElsIf TSRow.Count = 0 Then
		Return "";
	Else
		
		If TSRow.Property("Products") Then
			
			If Not TSRow.Characteristic.IsEmpty() Then
				
				Return StringFunctionsClient.FormattedString(NStr("vi = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5';
																	|ru = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5';
																	|en = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5'; fa = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5';
																	|it = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5';
																	|pl = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5';
																	|tr = '<a href=""%1"">%2</a>, <a href=""%3"">%4</a>: %5'"),
					GetURL(TSRow.Products),
					String(TSRow.Products),
					GetURL(TSRow.Characteristic),
					String(TSRow.Characteristic),
					TSRow[PathToDecryption]);
					
			EndIf;
			
			Return StringFunctionsClient.FormattedString(NStr("vi = '<a href=""%1"">%2</a>: %3';
																|ru = '<a href=""%1"">%2</a>: %3';
																|en = '<a href=""%1"">%2</a>: %3'; fa = '<a href=""%1"">%2</a>: %3';
																|it = '<a href=""%1"">%2</a>: %3';
																|pl = '<a href=""%1"">%2</a>: %3';
																|tr = '<a href=""%1"">%2</a>: %3'"),
					GetURL(TSRow.Products),
					String(TSRow.Products),
					TSRow[PathToDecryption]);
				
		ElsIf TSRow.Property("ProductCategory") Then
			
			Return StringFunctionsClient.FormattedString(NStr("vi = '<a href=""%1"">%2</a>: %3';
																|ru = '<a href=""%1"">%2</a>: %3';
																|en = '<a href=""%1"">%2</a>: %3'; fa = '<a href=""%1"">%2</a>: %3';
																|it = '<a href=""%1"">%2</a>: %3';
																|pl = '<a href=""%1"">%2</a>: %3';
																|tr = '<a href=""%1"">%2</a>: %3'"),
					GetURL(TSRow.ProductCategory),
					String(TSRow.ProductCategory),
					TSRow[PathToDecryption]);
				
		EndIf;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function FunctionsFromCommonModule() Export
	
	DetailsList1 = ProcessingOfFormulasClientServer.CommonModuleFunctions();
	
	FunctionDescription_ = ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction();
	FunctionDescription_.Id = "CurrentColumnNumber";
	FunctionDescription_.FullPath = "PlanningClientServer.CurrentColumnNumber";
	FunctionDescription_.Presentation = NStr("vi = 'Số cột hiện tại';
											|ru = 'Номер текущей колонки';
											|en = 'Current column number'; fa = 'Current column number';
											|it = 'Numero della colonna corrente';
											|pl = 'Numer bieżącej kolumny';
											|tr = 'Mevcut sütunun numarası'");
	FunctionDescription_.StructureToInsert = "CurrentColumnNumber()";
	FunctionDescription_.Explanation = NStr("vi = 'Tính số cột hiện tại';
											|ru = 'Вычисление номера текущей колонки';
											|en = 'Calculating current column number'; fa = 'Calculating current column number';
											|it = 'Calcolo del numero della colonna corrente';
											|pl = 'Obliczanie numeru bieżącej kolumny';
											|tr = 'Mevcut sütun sayısı hesaplaması'");
	DetailsList1.Add(FunctionDescription_);
	
	FunctionDescription_ = ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction();
	FunctionDescription_.Id = "ColumnValue";
	FunctionDescription_.FullPath = "PlanningClientServer.ColumnValue";
	FunctionDescription_.Presentation = NStr("vi = 'Giá trị cột';
											|ru = 'Значение колонки';
											|en = 'Column value'; fa = 'Column value';
											|it = 'Valore della colonna';
											|pl = 'Wartość kolumny';
											|tr = 'Sütun değeri'");
	FunctionDescription_.StructureToInsert = "ColumnValue()";
	FunctionDescription_.Explanation = NStr("vi = 'Tính giá trị cột';
											|ru = 'Вычисление значения колонки';
											|en = 'Calculating column value'; fa = 'Calculating column value';
											|it = 'Calcolo del valore della colonna';
											|pl = 'Obliczanie wartości kolumny';
											|tr = 'Sütun değeri hesaplaması'");
	DetailsList1.Add(FunctionDescription_);
	
	Return DetailsList1;
	
EndFunction

// Parameters:
// 	Result - Structure -
// 	AdditionalParameters - Structure - Content:
// 	  * Form - ClientApplicationForm - 
// 	Template Formulas - String-Description
Procedure CancelPlanLinesCompletion(Result, AdditionalParameters) Export 
	
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		Return
	EndIf;
	
	Form = AdditionalParameters.Form;
	NameOfTableElement = AdditionalParameters.NameOfTableElement;
	Items = Form.Items;
	
	If Form.Object.CrossTable Then
		
		SelectedRows = Items[NameOfTableElement].SelectedRows;
		
		If Result = DialogReturnCode.Yes Then
		
			ActivePeriods = Form.TimeIntervals.FindRows(New Structure("Active_", True));
			If ActivePeriods.Count() = 0  Then
				Return;
			EndIf;
			
			For Each SelectedRow In SelectedRows Do
				
				TSRow = AdditionalParameters.Table.FindByID(SelectedRow);
				For Each Period In ActivePeriods Do
					TSRow["Canceled_"+Period.ColumnName] = AdditionalParameters.Canceled;
				EndDo;
				
			EndDo; 
			
		Else
		
			For Each SelectedRow In SelectedRows Do
				
				TSRow = AdditionalParameters.Table.FindByID(SelectedRow);
				TSRow["Canceled_"+AdditionalParameters.ColumnName] = AdditionalParameters.Canceled;
				
			EndDo; 
		
		EndIf; 
	
	Else
	
		SelectedRows = Items[NameOfTableElement].SelectedRows;
		For Each SelectedRow In SelectedRows Do
		
			TSRow = AdditionalParameters.Table.FindByID(SelectedRow);
			TSRow.Canceled = AdditionalParameters.Canceled;
		
		EndDo; 
	
	EndIf; 
	
	If AdditionalParameters.Property("ClosingNotification1") Then
		RunCallback(AdditionalParameters.ClosingNotification1, Result);
	EndIf;
	
EndProcedure

Procedure ShowQuestionWhenScriptChangesCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		PlanningClientServer.RestoreValuesFromVerifiedDetails(
			AdditionalParameters.Form.Object, 
			AdditionalParameters.Form, 
			"DetailsBeforeChange", 
			"Scenario, PlanProfile");
	EndIf;
	
	If AdditionalParameters.Property("ClosingNotification1") Then
		RunCallback(AdditionalParameters.ClosingNotification1, Result);
	EndIf;
	
EndProcedure

Procedure ShowQuestionWhenChangingPlanViewCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		PlanningClientServer.RestoreValuesFromVerifiedDetails(
			AdditionalParameters.Form.Object, 
			AdditionalParameters.Form, 
			"DetailsBeforeChange", 
			"PlanProfile");
	EndIf;
	
	If AdditionalParameters.Property("ClosingNotification1") Then
		RunCallback(AdditionalParameters.ClosingNotification1, Result);
	EndIf;
	
EndProcedure

Procedure EnterPercentageAndChangeFormula(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		AdditionalParameters.Insert("ColumnName", "AllPeriods");
	ElsIf Result <> DialogReturnCode.No Then
		If AdditionalParameters.Property("ClosingNotification1") Then
			RunCallback(AdditionalParameters.ClosingNotification1, Result);
		EndIf;
		Return;
	EndIf;
	
	Notification = New CallbackDescription("EnterPercentageAndChangeFormulaCompletion", ThisObject, AdditionalParameters);
	
	ShowInputNumber(Notification, 0, NStr("vi = 'Hãy nhập phần trăm';
											|ru = 'Введите процент';
											|en = 'Enter the percentage'; fa = 'Enter the percentage';
											|it = 'Inserire una percentuale';
											|pl = 'Wprowadź procent';
											|tr = 'Yüzdeyi girin'"), 5, 2);
	
EndProcedure

Procedure EnterPercentageAndChangeFormulaCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result = 0 Then
		Return;
	EndIf;
	
	Percent = Format(1 + Result / 100 ,"ND=15; NFD=4; NDS=.");
	
	FormulaTemplate = NStr("vi = '(%CurFormula%) * %Percent%';
							|ru = '(%CurFormula%) * %Percent%';
							|en = '(%CurFormula%) * %Percent%'; fa = '(%CurFormula%) * %Percent%';
							|it = '(%CurFormula%) * %Percent%';
							|pl = '(%CurFormula%) * %Percent%';
							|tr = '(%CurFormula%) * %Percent%'");
	FormulaTemplate = StrReplace(FormulaTemplate, "%Percent%", Percent);
	
	ChangeFormulaOfSelectedRowsByPattern(Result, AdditionalParameters, FormulaTemplate);
	
EndProcedure

Procedure SelectRoundingAccuracyChangeFormula(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		AdditionalParameters.Insert("ColumnName", "AllPeriods");
	ElsIf Result <> DialogReturnCode.No Then
		If AdditionalParameters.Property("ClosingNotification1") Then
			RunCallback(AdditionalParameters.ClosingNotification1, Result);
		EndIf;
		Return;
	EndIf;
	
	ValueList = New ValueList();
	ValueList.Add( 3, "0,001");
	ValueList.Add( 2, "0,01");
	ValueList.Add( 1, "0,1");
	ValueList.Add( 0, "1");
	ValueList.Add(-1, "10");
	ValueList.Add(-2, "100");
	ValueList.Add(-3, "1000");
	
	
	Notification = New CallbackDescription("SelectRoundingAccuracyChangeFormulaCompletion", ThisObject, AdditionalParameters);
	
	ValueList.ShowChooseItem(Notification,NStr("vi = 'Độ chính xác làm tròn';
												|ru = 'Точность округления';
												|en = 'Rounding precision'; fa = 'دقت گرد کردن';
												|it = 'Precisione di arrotondamento';
												|pl = 'Dokładność zaokrąglania';
												|tr = 'Yuvarlama duyarlılığı'"));
	
EndProcedure

Procedure SelectRoundingAccuracyChangeFormulaCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FormulaTemplate = NStr("vi = 'Làm tròn((%CurFormula%), %RoundingPrecision%)';
							|ru = 'Окр((%CurFormula%), %RoundingPrecision%)';
							|en = 'Round((%CurFormula%), %RoundingPrecision%)'; fa = 'Round((%CurFormula%), %RoundingPrecision%)';
							|it = 'Arrotondamento((%CurFormula%), %RoundingPrecision%)';
							|pl = 'Zaokr((%CurFormula%), %RoundingPrecision%)';
							|tr = 'Yuv((%CurFormula%), %RoundingPrecision%)'");
	FormulaTemplate = StrReplace(FormulaTemplate, "%RoundingPrecision%", Result.Value);
	
	ChangeFormulaOfSelectedRowsByPattern(Result, AdditionalParameters, FormulaTemplate);
	
EndProcedure

// Parameters:
// 	Result - Structure -
// 	Parameters - Structure - Content:
// 	  * Form - ClientApplicationForm - 
// 	FormulaTemplate - String - LongDesc
Procedure ChangeFormulaOfSelectedRowsByPattern(Result, Parameters, FormulaTemplate)
	
	Form = Parameters.Form;
	Items = Form.Items;
	NameOfTableElement = Parameters.NameOfTableElement;
	Table = Parameters.Table;
	ColumnName = Parameters.ColumnName;
	
	SelectedRows = Items[NameOfTableElement].SelectedRows;
	
	If Form.Object.CrossTable Then
		
		For Each SelectedRow In SelectedRows Do
			
			If ColumnName = "AllPeriods" Then
				TimeIntervals = Form.TimeIntervals.FindRows(New Structure("Active_", True));
			Else
				TimeIntervals = Form.TimeIntervals.FindRows(New Structure("Active_, ColumnName", True, ColumnName))
			EndIf;
			
			For Each Period In TimeIntervals Do
				
				TSRow = Table.FindByID(SelectedRow);
				If TSRow.Property("SemiFinishedProduct")
					And TSRow.SemiFinishedProduct Then
					Continue;
				EndIf;
				If ValueIsFilled(TSRow["Formula_" + Period.ColumnName]) Then
					TSRow["Formula_" + Period.ColumnName] = StrReplace(FormulaTemplate, "%CurFormula%", TSRow["Formula_" + Period.ColumnName]);
				Else
					TSRow["Formula_" + Period.ColumnName] = Format(TSRow["Count_" + Period.ColumnName], "NDS=.; NZ=0; NG=0");
					TSRow["Formula_" + Period.ColumnName] = StrReplace(FormulaTemplate, "%CurFormula%", TSRow["Formula_" + Period.ColumnName]);
				EndIf; 
				CalculationResult = CalculateByFormula(TSRow["Formula_" + Period.ColumnName], TSRow, TimeIntervals, Period);
				TSRow["FormulaCalculation_" + Period.ColumnName] = CalculationResult.Calculation;
				TSRow["Count_" + Period.ColumnName]= CalculationResult.Result;
				TSRow["Deviation_" + Period.ColumnName]= 0;
				
			EndDo;
			
		EndDo; 

	Else
		
		For Each SelectedRow In SelectedRows Do
			
			TSRow = Table.FindByID(SelectedRow);
			If ValueIsFilled(TSRow.Formula) Then
				TSRow.Formula = StrReplace(FormulaTemplate, "%CurFormula%", TSRow.Formula);
			Else
				TSRow.Formula = Format(TSRow[ColumnName], "NDS=.; NZ=0; NG=0");
				TSRow.Formula = StrReplace(FormulaTemplate, "%CurFormula%", TSRow.Formula);
			EndIf; 
			CalculationResult = CalculateByFormula(TSRow.Formula, TSRow, Undefined, Undefined);
			TSRow.FormulaCalculation = CalculationResult.Calculation;
			TSRow[ColumnName] = CalculationResult.Result;
			TSRow.Deviation = 0;
			
		EndDo;
		
	EndIf;
	
	If Parameters.Property("ClosingNotification1") Then
		RunCallback(Parameters.ClosingNotification1, Result);
	EndIf;
	
EndProcedure

Procedure WhenChangingPlanPeriodCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
	
		RunCallback(AdditionalParameters.InterfaceUpdateAlert);
	
	Else
	
		PlanningClientServer.RestoreValuesFromVerifiedDetails(
			AdditionalParameters.Form.Object, 
			AdditionalParameters.Form, 
			"DetailsBeforeChange", 
			"BeginOfPeriod, PeriodEnding");
	
	EndIf; 
	
EndProcedure


// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	ProductsPageName - String -
// 	NameTSGoods - String -
// 	NameTSProductsByPeriod - String -
Procedure PositionByLine(Form, ProductsPageName, NameTSGoods, NameTSProductsByPeriod) Export
	
	If ValueIsFilled(Form.CurrentRowWhenOpening) Then
		Form.Items.GroupPages.CurrentPage = Form.Items[ProductsPageName];
		If Form.Object.CrossTable Then
			SearchBars = Form[NameTSProductsByPeriod].FindRows(Form.CurrentRowWhenOpening);
			If SearchBars.Count()>0 Then
				GoodsByPeriod = Form.Items[NameTSProductsByPeriod]; // FormTable - 
				GoodsByPeriod.CurrentRow = SearchBars[0].GetID();
			EndIf;
		Else
			SearchBars = Form.Object[NameTSGoods].FindRows(Form.CurrentRowWhenOpening);
			If SearchBars.Count()>0 Then
				Goods = Form.Items[NameTSProductsByPeriod]; // FormTable - 
				Goods.CurrentRow = SearchBars[0].GetID();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
//  ValueSelected - CatalogRef.Warehouses, CatalogRef.Assignments, CatalogRef.Partners - value for filling columns
//  AdditionalParameters - Structure:
//	*SelectedRows - Array of Number
//	*GoodsTable - ValueTable, TabularSection -
//	*Column - String
Procedure FillInByCompletionValue(ValueSelected, AdditionalParameters) Export
	
	If ValueIsFilled(ValueSelected) Then
		
		SelectedRows = AdditionalParameters.SelectedRows;
		For Each CurRow In SelectedRows Do
			
			TableRow = AdditionalParameters.GoodsTable.FindByID(CurRow);
			
			If AdditionalParameters.Column = "Warehouse" And TableRow.Property("ItemsType")
				And (TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
				Or TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")) Then
				Continue;
			EndIf;
			
			TableRow[AdditionalParameters.Column] = ValueSelected;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#Region ImportDataFromFile

// Parameters:
//  AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
// 
// Returns:
//  Array of See ImportDataFromFileClientServer.TemplateColumnDetails - Description Of The Template Columns For Loading Products
Function DescriptionOfTemplateColumnsForLoadingProducts(AdditionalParameters) Export
	
	CrossTable = AdditionalParameters.CrossTable;
	TablePeriods = AdditionalParameters.TimeIntervals;
	
	TemplateColumns = New Array;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Barcode", New TypeDescription("String",, New StringQualifiers(200)), NStr("vi = 'Mã vạch';
																																			|ru = 'Штрихкод';
																																			|en = 'Barcode'; fa = 'بارکد';
																																			|it = 'Codice a barre';
																																			|pl = 'Kod kreskowy';
																																			|tr = 'Barkod'"), 10);
	Column.Position = TemplateColumns.UBound() + 1;
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("SKU", New TypeDescription("String",, New StringQualifiers(50)), NStr("vi = 'Mã hiệu';
																																		|ru = 'Артикул';
																																		|en = 'Item ID'; fa = 'شناسه قلم';
																																		|it = 'Articolo';
																																		|pl = 'Artykuł';
																																		|tr = 'Ürün kodu'"), 10);
	Column.Position = TemplateColumns.UBound() + 1;
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductsAndServicesCode", New TypeDescription("String",, New StringQualifiers(11)), NStr("vi = 'Mã hàng';
																																							|ru = 'Код номенклатуры';
																																							|en = 'Items code'; fa = 'کد اقلام';
																																							|it = 'Codice dell''elenco articoli';
																																							|pl = 'Kod towaru';
																																							|tr = 'Öğe kodu'"), 15);
	Column.Position = TemplateColumns.UBound() + 1;
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Products", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Mặt hàng';
																																				|ru = 'Номенклатура';
																																				|en = 'Item'; fa = 'قلم';
																																				|it = 'Articolo';
																																				|pl = 'Produkt';
																																				|tr = 'Ürün'"), 15);
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Characteristic", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Đặc tính';
																																					|ru = 'Характеристика';
																																					|en = 'Variant'; fa = 'گونه';
																																					|it = 'Caratteristica';
																																					|pl = 'Charakterystyka';
																																					|tr = 'Varyant'"), 15);
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	If AdditionalParameters.AssignmentsAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Purpose", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Chỉ định';
																																				|ru = 'Назначение';
																																				|en = 'Assignment'; fa = 'تخصیص';
																																				|it = 'Assegnazione';
																																				|pl = 'Przeznaczenie';
																																				|tr = 'Atama'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("PackageCode", New TypeDescription("String",, New StringQualifiers(4)), NStr("vi = 'Mã đóng gói';
																																				|ru = 'Код упаковки';
																																				|en = 'Packaging unit code'; fa = 'کد واحد بسته‌بندی';
																																				|it = 'Codice di imballaggio';
																																				|pl = 'Kod opakowania';
																																				|tr = 'Paketleme ünitesi kodu'"), 12);
	Column.Position = TemplateColumns.UBound() + 1;
	Column.Parent = "Package";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Package", New TypeDescription("String",, New StringQualifiers(50)), NStr("vi = 'Bộ đóng gói';
																																			|ru = 'Упаковка';
																																			|en = 'Packaging unit'; fa = 'واحد بسته‌بندی';
																																			|it = 'Imballaggio';
																																			|pl = 'Opakowanie';
																																			|tr = 'Paket'"), 10);
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	If Not CrossTable Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("NumberOfPackages", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Số lượng';
																																							|ru = 'Количество';
																																							|en = 'Quantity'; fa = 'مقدار';
																																							|it = 'Quantità';
																																							|pl = 'Ilość';
																																							|tr = 'Miktar'"), 10);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	// Production plan
	If AdditionalParameters.SpecificationsAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("BillOfMaterials", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
																																						|ru = 'Спецификация';
																																						|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																																						|it = 'Specifica';
																																						|pl = 'Specafikacja';
																																						|tr = 'Ürün reçetesi'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	If AdditionalParameters.WarehousesAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Warehouse", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Kho bãi';
																																					|ru = 'Склад';
																																					|en = 'Warehouse'; fa = 'Warehouse';
																																					|it = 'Magazzino';
																																					|pl = 'Magazyn';
																																					|tr = 'Ambar'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.PartnersAreUsed Then
		Title = ?(AdditionalParameters.PlanType = "PurchasePlan", NStr("vi = 'Nhà cung cấp';
																		|ru = 'Поставщик';
																		|en = 'Vendor'; fa = 'تأمین‌کننده';
																		|it = 'Fornitore';
																		|pl = 'Dostawca';
																		|tr = 'Tedarikçi'"), NStr("vi = 'Khách hàng';
																								|ru = 'Клиент';
																								|en = 'Customer'; fa = 'مشتری';
																								|it = 'Cliente';
																								|pl = 'Klient';
																								|tr = 'İstemci'"));
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Partner", New TypeDescription("String",, New StringQualifiers(150)), Title, 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.AgreementsAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Terms", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Thỏa thuận';
																																				|ru = 'Соглашение';
																																				|en = 'Agreement'; fa = 'توافق‌نامه';
																																				|it = 'Accordo';
																																				|pl = 'Porozumienie:';
																																				|tr = 'Anlaşma'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.TypesOfPricesAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("PriceKind", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Dạng giá';
																																					|ru = 'Вид цены';
																																					|en = 'Price type'; fa = 'نوع قیمت';
																																					|it = 'Tipo di prezzo';
																																					|pl = 'Rodzaj ceny';
																																					|tr = 'Fiyat türü'"), 10);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If Not CrossTable And AdditionalParameters.PlanByAmount Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Price", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Đơn giá';
																																				|ru = 'Цена';
																																				|en = 'Price'; fa = 'قیمت';
																																				|it = 'Prezzo';
																																				|pl = 'Cena';
																																				|tr = 'Fiyat'"), 10);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Sum", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Tổng số';
																																				|ru = 'Сумма';
																																				|en = 'Amount'; fa = 'مبلغ';
																																				|it = 'Importo';
																																				|pl = 'Wartość';
																																				|tr = 'Tutar'"), 10);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.PlanType = "AssemblyDisassemblyPlan" Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductKit", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Đóng bộ';
																																					|ru = 'Комплектация';
																																					|en = 'Product kit'; fa = 'کیت کالا';
																																					|it = 'Componenti';
																																					|pl = 'Kompletacja';
																																					|tr = 'Ürün seti'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		If Not CrossTable Then
			Column = ImportDataFromFileClientServer.TemplateColumnDetails("DateOfAssemblyDisassembly", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày đóng bộ (tách bộ)';
																																								|ru = 'Дата сборки (разборки)';
																																								|en = 'Date of kitting'; fa = 'تاریخ کیت‌سازی';
																																								|it = 'Data di assemblaggio (disassemblaggio)';
																																								|pl = 'Data montażu (demontażu)';
																																								|tr = 'Montaj (demontaj) tarihi'"), 15);
			Column.Position = TemplateColumns.UBound() + 1;
			TemplateColumns.Add(Column);
		EndIf;
	EndIf;
	If Not CrossTable And AdditionalParameters.ReleaseDatesAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("DateOfProduction", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày xuất xưởng';
																																					|ru = 'Дата выпуска';
																																					|en = 'Release date'; fa = 'تاریخ انتشار';
																																					|it = 'Data di produzione';
																																					|pl = 'Data wydania';
																																					|tr = 'Çıkış tarihi'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If Not CrossTable And AdditionalParameters.ReleaseDatesOfSemiFinishedProductAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("ReleaseDateOfProductsOrSemiFinishedProduct", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày xuất xưởng sản phẩm bán thành phẩm';
																																											|ru = 'Дата выпуска продукции полуфабриката';
																																											|en = 'Release date of products or semi-finished product'; fa = 'تاریخ تولید محصولات یا محصول نیمه‌ساخته';
																																											|it = 'Data di rilascio dei prodotti del prodotto semilavorato';
																																											|pl = 'Data produkcji półproduktu';
																																											|tr = 'Yarı mamul ürün çıkış tarihi'"), 20);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If Not CrossTable And AdditionalParameters.PlanType = "ProductionPlan" Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("StartDate2", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày vận hành';
																																			|ru = 'Дата запуска';
																																			|en = 'Launch date'; fa = 'تاریخ شروع';
																																			|it = 'Data di avvio';
																																			|pl = 'Data uruchomienia';
																																			|tr = 'Başlangıç tarihi'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	If Not CrossTable And AdditionalParameters.PlanType = "PurchasePlan" Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("DateOfReceipt", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày tiếp nhận';
																																				|ru = 'Дата поступления';
																																				|en = 'Date of receipt'; fa = 'تاریخ دریافت';
																																				|it = 'Data di ricezione';
																																				|pl = 'Data wpływu';
																																				|tr = 'Giriş tarihi'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("OrderDate", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày trong đơn hàng';
																																			|ru = 'Дата заказа';
																																			|en = 'Order date'; fa = 'تاریخ سفارش';
																																			|it = 'Data dell''ordine';
																																			|pl = 'Data zamówienia';
																																			|tr = 'Sipariş tarihi'"), 10);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("OrderFulfillmentPeriod", New TypeDescription("Number",, New NumberQualifiers(8, 0)), NStr("vi = 'Thời hạn thực hiện';
																																								|ru = 'Срок исполнения';
																																								|en = 'Due date'; fa = 'تاریخ سررسید';
																																								|it = 'Tempo di esecuzione';
																																								|pl = 'Data realizacji';
																																								|tr = 'Son tarih'"), 13);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If Not CrossTable And (AdditionalParameters.PlanType = "InventoryConsumptionPlan"
		Or AdditionalParameters.PlanType = "SalesPlan") Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("DateOfShipment", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày giao hàng';
																																				|ru = 'Дата отгрузки';
																																				|en = 'Shipment date'; fa = 'تاریخ ارسال';
																																				|it = 'Data di spedizione';
																																				|pl = 'Data wysyłki';
																																				|tr = 'Sevkiyat tarihi'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If CrossTable Then
		For Each Period In TablePeriods Do
			
			If AdditionalParameters.PlanByAmount Then
				ColumnName = "NumberOfPackages_" + Period.ColumnName;
				Column = ImportDataFromFileClientServer.TemplateColumnDetails(ColumnName, New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Số lượng';
																																							|ru = 'Количество';
																																							|en = 'Quantity'; fa = 'مقدار';
																																							|it = 'Quantità';
																																							|pl = 'Ilość';
																																							|tr = 'Miktar'") + " " + Period.Title, 15);
				Column.Position = TemplateColumns.UBound() + 1;
				TemplateColumns.Add(Column);
				
				ColumnName = "Price_" + Period.ColumnName;
				Column = ImportDataFromFileClientServer.TemplateColumnDetails(ColumnName, New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Đơn giá';
																																							|ru = 'Цена';
																																							|en = 'Price'; fa = 'قیمت';
																																							|it = 'Prezzo';
																																							|pl = 'Cena';
																																							|tr = 'Fiyat'") + " " + Period.Title, 15);
				Column.Position = TemplateColumns.UBound() + 1;
				TemplateColumns.Add(Column);
				
				ColumnName = "Sum_" + Period.ColumnName;
				Column = ImportDataFromFileClientServer.TemplateColumnDetails(ColumnName, New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Tổng số';
																																							|ru = 'Сумма';
																																							|en = 'Amount'; fa = 'مبلغ';
																																							|it = 'Importo';
																																							|pl = 'Wartość';
																																							|tr = 'Tutar'") + " " + Period.Title, 15);
				Column.Position = TemplateColumns.UBound() + 1;
				TemplateColumns.Add(Column);
			Else
				ColumnName = "NumberOfPackages_" + Period.ColumnName;
				Column = ImportDataFromFileClientServer.TemplateColumnDetails(ColumnName, New TypeDescription("Number",, New NumberQualifiers(15, 3)), Period.Title, 10);
				Column.Position = TemplateColumns.UBound() + 1;
				TemplateColumns.Add(Column);
			EndIf;
			
		EndDo;
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Comment", New TypeDescription("String",, New StringQualifiers(0)), NStr("vi = 'Diễn giải';
																																			|ru = 'Комментарий';
																																			|en = 'Comment'; fa = 'توضیحات';
																																			|it = 'Commento';
																																			|pl = 'Uwagi';
																																			|tr = 'Yorum'"), 20);
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	Return TemplateColumns;
	
EndFunction

// Parameters:
//  AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
// 
// Returns:
//  Array of See ImportDataFromFileClientServer.TemplateColumnDetails - Description Of The Template Columns For Loading Products
Function DescriptionOfTemplateColumnsForLoadingProductCategories(AdditionalParameters) Export
	TemplateColumns = New Array;
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductCategory", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Thể loại hàng hóa';
																																					|ru = 'Товарная категория';
																																					|en = 'Product category'; fa = 'دسته محصول';
																																					|it = 'Categoria merceologica';
																																					|pl = 'Kategoria produktu';
																																					|tr = 'Ürün kategorisi'"), 15);
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	If AdditionalParameters.AssignmentsAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Purpose", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Ấn định';
																																				|ru = 'Назначение';
																																				|en = 'Assignment'; fa = 'تخصیص';
																																				|it = 'Assegnazione';
																																				|pl = 'Przeznaczenie';
																																				|tr = 'Atama'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.CalculationOfSalesRateIsUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("SalesRank", New TypeDescription("String",, New StringQualifiers(100)), NStr("vi = 'Đánh giá bán hàng';
																																					|ru = 'Рейтинг продаж';
																																					|en = 'Sales rank'; fa = 'رتبه فروش';
																																					|it = 'Ranking delle vendite';
																																					|pl = 'Ranking sprzedaży';
																																					|tr = 'Satış sıralaması'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.WarehousesAreUsed Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Warehouse", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Kho bãi';
																																					|ru = 'Склад';
																																					|en = 'Warehouse'; fa = 'Warehouse';
																																					|it = 'Magazzino';
																																					|pl = 'Magazyn';
																																					|tr = 'Ambar'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	If AdditionalParameters.CrossTable Then
		For Each Period In AdditionalParameters.TimeIntervals Do
			ColumnName = "Count_" + Period.ColumnName;
			Column = ImportDataFromFileClientServer.TemplateColumnDetails(ColumnName, New TypeDescription("Number",, New NumberQualifiers(15, 3)), Period.Title, 10);
			Column.Position = TemplateColumns.UBound() + 1;;
			TemplateColumns.Add(Column);
		EndDo;
	Else
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Count", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Số lượng';
																																				|ru = 'Количество';
																																				|en = 'Quantity'; fa = 'مقدار';
																																				|it = 'Quantità';
																																				|pl = 'Ilość';
																																				|tr = 'Miktar'"), 10);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("DateOfShipment", New TypeDescription("Date",, New DateQualifiers()), NStr("vi = 'Ngày giao hàng';
																																				|ru = 'Дата отгрузки';
																																				|en = 'Shipment date'; fa = 'تاریخ ارسال';
																																				|it = 'Data di spedizione';
																																				|pl = 'Data wysyłki';
																																				|tr = 'Sevkiyat tarihi'"), 15);
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Comment", New TypeDescription("String",, New StringQualifiers(0)), NStr("vi = 'Diễn giải';
																																			|ru = 'Комментарий';
																																			|en = 'Comment'; fa = 'توضیحات';
																																			|it = 'Commento';
																																			|pl = 'Uwagi';
																																			|tr = 'Yorum'"), 20);
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	Return TemplateColumns;
EndFunction

// Additional parameters for downloading from a file.
// 
// Returns:
//  Structure - Additional Parameters For Downloading From A File:
// * PlanType - String -
// * AssignmentsAreUsed - Boolean -
// * PartnersAreUsed - Boolean -
// * TypesOfPricesAreUsed - Boolean -
// * WarehousesAreUsed - Boolean -
// * AgreementsAreUsed - Boolean -
// * PlanByAmount - Boolean -
// * Vendor - CatalogRef.Partners,Undefined -
// * SpecificationsAreUsed - Boolean -
// * ReleaseDatesAreUsed - Boolean -
// * ReleaseDatesOfSemiFinishedProductAreUsed - Boolean -
// * CalculationOfSalesRateIsUsed - Boolean -
// * AvailableProductTypes - Array of EnumRef.ItemsTypes -
// * CrossTable - Boolean -
// * TimeIntervals - FormDataCollection -
Function AdditionalParametersForDownloadingFromFile() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PlanType",               "");
	AdditionalParameters.Insert("AssignmentsAreUsed", False);
	AdditionalParameters.Insert("PartnersAreUsed",   False);
	AdditionalParameters.Insert("TypesOfPricesAreUsed",    False);
	AdditionalParameters.Insert("WarehousesAreUsed",     False);
	AdditionalParameters.Insert("AgreementsAreUsed", False);
	AdditionalParameters.Insert("PlanByAmount",     False);
	AdditionalParameters.Insert("Partner",              Undefined);
	AdditionalParameters.Insert("SpecificationsAreUsed",                      False);
	AdditionalParameters.Insert("ReleaseDatesAreUsed",                       False);
	AdditionalParameters.Insert("ReleaseDatesOfSemiFinishedProductAreUsed", False);
	AdditionalParameters.Insert("CalculationOfSalesRateIsUsed", False);
	
	AdditionalParameters.Insert("AvailableProductTypes", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
	AdditionalParameters.Insert("CrossTable", False);
	AdditionalParameters.Insert("TimeIntervals", Undefined);
	
	Return AdditionalParameters;
EndFunction

#EndRegion

#EndRegion