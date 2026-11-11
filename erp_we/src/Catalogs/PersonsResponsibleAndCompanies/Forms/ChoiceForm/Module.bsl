
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") And Parameters.Filter.Property("Date") Then
		
		// We will impose a selection of the list by the period of validity of the record - it must coincide with the date of the document
		//	- beginning of the period <= document date
		//	- end of the period >= document dates or the end date of the period is not specified.
		
		DateForFilter 	 = Parameters.Filter.Date;
		ViewMode = DataCompositionSettingsItemViewMode.QuickAccess;
		
		SelectionGroupByPeriod = CommonClientServer.CreateFilterItemGroup(
			TMCommonUseClientServer.GetDynamicListSelection(List).Items,
			NStr("vi = 'Kỳ hiệu lực';
				|ru = 'Период действия';
				|en = 'Validity period'; fa = 'دوره اعتبار';
				|it = 'Periodo di validità';
				|pl = 'Okres ważności';
				|tr = 'Geçerlilik dönemi'"),
			DataCompositionFilterItemsGroupType.AndGroup);
		
		CommonClientServer.AddCompositionItem(
			SelectionGroupByPeriod,
			"StartDate",
			DataCompositionComparisonType.LessOrEqual,
			DateForFilter,,
			True,
			ViewMode);
		
		SelectionGroupByEndDate = CommonClientServer.CreateFilterItemGroup(
			SelectionGroupByPeriod.Items,
			NStr("vi = 'Ngày kết thúc';
				|ru = 'Дата окончания';
				|en = 'End date'; fa = 'تاریخ پایان';
				|it = 'Data di fine';
				|pl = 'Data zakończenia';
				|tr = 'Bitiş tarihi'"),
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			SelectionGroupByEndDate,
			"EndDate",
			DataCompositionComparisonType.GreaterOrEqual,
			DateForFilter,,
			True,
			ViewMode);
		
		CommonClientServer.AddCompositionItem(
			SelectionGroupByEndDate,
			"EndDate",
			DataCompositionComparisonType.NotFilled,
			DateForFilter,,
			True,
			ViewMode);
		
		SelectionGroupByPeriod.ViewMode 		 = ViewMode;
		SelectionGroupByEndDate.ViewMode = ViewMode;
		
		Parameters.Filter.Delete("Date");
		
	EndIf;
	
	If GetFunctionalOption("BaseVersion") Then
		Items.Individual.Title = NStr("vi = 'Nhân viên';
										|ru = 'Сотрудник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Pracownik';
										|tr = 'Çalışan'");
	EndIf;
	
	Items.Owner.Visible = GetFunctionalOption("UseMultipleCompanies");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

