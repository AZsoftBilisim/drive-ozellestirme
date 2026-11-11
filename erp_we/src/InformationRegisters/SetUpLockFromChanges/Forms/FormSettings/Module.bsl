// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If ValueIsFilled(Parameters.RegistrationPeriod) Then
		// The Form is open from the month closing Form
		//@skip-check property-return-type
		AvailableCompanies = Parameters.CompanyArray; // Array of CatalogRef.Companies
		SourcePeriod = BegOfMonth(Parameters.RegistrationPeriod);
		FormIsOpenContextually = True;
	Else
		AvailableCompanies = Catalogs.Companies.AvailableCompanies(True);
		SourcePeriod = Undefined;
		FormIsOpenContextually = False;
	EndIf;
	
	Lock_Settings = InformationRegisters.SetUpLockFromChanges.InformationAboutBlockingChanges(AvailableCompanies);
	
	For Each CurrRow In Lock_Settings.TableOfLocks Do
		
		If ValueIsFilled(SourcePeriod) And CurrRow.BlockingPeriod >= SourcePeriod Then
			Continue; // the period for the organization has already been blocked
		EndIf;
		NwRw = BlockingChanges.Add();
		NwRw.Organization = CurrRow.Organization;
		NwRw.BlockedPeriod = CurrRow.BlockingPeriod;
		NwRw.CanBeBlockedBy = CurrRow.PossibleBlockingPeriod;
		NwRw.SourcePeriod = NwRw.BlockedPeriod;
		
		If ValueIsFilled(SourcePeriod) Then
			NwRw.BlockedPeriod = SourcePeriod;
		EndIf;
		
		NwRw.BlockedPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(NwRw.BlockedPeriod);
		NwRw.CanBeBlockedByPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(NwRw.CanBeBlockedBy);
		
		If Not ValueIsFilled(CurrRow.ChangeDate) Then
			NwRw.InfoAboutLock = NStr("vi = 'Chưa đặt phong tỏa';
										|ru = 'Блокировка не установлена';
										|en = 'Lock is not set'; fa = 'Lock is not set';
										|it = 'Блокировка не установлена';
										|pl = 'Lock is not set';
										|tr = 'Kilit ayarlanmadı'");
		Else
			NwRw.InfoAboutLock = NStr("vi = 'Đã thiết lập phong tỏa';
										|ru = 'Установлена блокировка';
										|en = 'Lock is set'; fa = 'Lock is set';
										|it = 'Установлена блокировка';
										|pl = 'Lock is set';
										|tr = 'Kilit ayarlandı'") + ": "
				+ Format(CurrRow.ChangeDate, "DLF=DT; DE=;") + ?(ValueIsFilled(CurrRow.ChangeDate), "; ", "")
				+ String(CurrRow.EmployeeResponsible) + ?(ValueIsFilled(CurrRow.EmployeeResponsible), "; ", "")
				+ TrimAll(CurrRow.Comment); 
		EndIf;
		
	EndDo;

	BlockingChanges.Sort("Organization");
	
	If BlockingChanges.Count() <= 1 Then
		Items.BlockingFromChangesCanBeSet.Visible = False;
	EndIf;
	
	If FormIsOpenContextually Then
		
		// Hide the extra controls
		Items.BlockingChanges.CommandBar.Visible = False;
		Items.BlockingFromChangesCanBeBlockedBy.Visible = False;
		Items.SetSoftwareLock.Visible = False;
		Items.BlockingFromChangesBlockedPeriod.Visible = False;
		
		Items.DecorationMessageAboutBlocking.Visible = True;
		Items.DecorationMessageAboutBlocking.Title =
			NStr("vi = 'Theo doanh nghiệp đã chỉ ra sẽ thiết lập phong tỏa tránh các thay đổi đối với kỳ';
				|ru = 'По указанным организациям будет установлена блокировка от изменений для периода';
				|en = 'The lock from changes will be set for the period by the specified companies'; fa = 'The lock from changes will be set for the period by the specified companies';
				|it = 'По указанным организациям будет установлена блокировка от изменений для периода';
				|pl = 'The lock from changes will be set for the period by the specified companies';
				|tr = 'Belirtilen iş yerleri dönem boyunca değişikliklerden engellenecektir'")
			+ " " + MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(SourcePeriod);
		
		ConditionalAppearance.Items.Clear();
		
	Else
		Items.DecorationMessageAboutBlocking.Visible = False;
	EndIf;
	
	ReadOnly = Not MonthEndTransactionsServer.YouHaveRightToManageBlockingOfPeriod();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBlockingChanges

&AtClient
Procedure BlockingChangesOnActivateCell(Item)
	
	CurrentData = Items.BlockingChanges.CurrentData;
	
	If Items.BlockingChanges.CurrentItem = Items.SetSoftwareLock
	 And CurrentData <> Undefined Then
		CurrentData.BlockedPeriod = CurrentData.CanBeBlockedBy;
		CurrentData.BlockedPeriodPresentation = CurrentData.CanBeBlockedByPresentation;
	EndIf;

	If CurrentData <> Undefined Then
		Items.InfoAboutLock.Title = CurrentData.InfoAboutLock;
	EndIf;
	
EndProcedure

&AtClient
Procedure BlockingFromChangesBlockedPeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("BlockedPeriodPresentationStartOfSelectionEnd", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Items.BlockingChanges.CurrentData.BlockedPeriod, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BlockingFromChangesBlockedPeriodTuning(Item, Direction, StandardProcessing)
	
	CurrentData = Items.BlockingChanges.CurrentData;
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		CurrentData.BlockedPeriod,
		CurrentData.BlockedPeriodPresentation);
	
	CurrentData.BlockedPeriod = Min(CurrentData.CanBeBlockedBy, CurrentData.BlockedPeriod);
	CurrentData.BlockedPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(CurrentData.BlockedPeriod);
	
EndProcedure

&AtClient
Procedure BlockingFromChangesBlockedPeriodClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure BlockingChangesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.BlockingChanges.CurrentData;
	
	If Items.BlockingChanges.CurrentItem = Items.BlockingChangesOrganization
	 And CurrentData <> Undefined Then
		ShowValue(, CurrentData.Organization);
 	EndIf;
 	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure BlockPeriod(Command)
	
	RecordPeriodLocks();
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("UpdateCloseMonthForm", True);
	
	Close(ClosingParameters);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure SetGeneralPeriod(Command)
	
	CloseHandler = New CallbackDescription("SetGeneralPeriodCompletion", ThisObject);
	FormParameters 	   = New Structure("PeriodSelectionMode", "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetMaximumPossiblePeriod(Command)
	
	For Each CurrRow In BlockingChanges Do
		
		CurrRow.BlockedPeriod = CurrRow.CanBeBlockedBy;
		CurrRow.BlockedPeriodPresentation = CurrRow.CanBeBlockedByPresentation;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

// blocked period Presentation the beginning of the selection End.
// 
// Parameters:
//  SelectedPeriod - Date - Selected period
//  AdditionalParameters - Arbitrary - advanced setting
&AtClient
Procedure BlockedPeriodPresentationStartOfSelectionEnd(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		CurrentData = Items.BlockingChanges.CurrentData;
		
		SelectedPeriod = Min(CurrentData.CanBeBlockedBy, SelectedPeriod);
		
		CurrentData.BlockedPeriod = SelectedPeriod;
		CurrentData.BlockedPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(SelectedPeriod);
		
	EndIf;
	
EndProcedure

// set the total End period.
// 
// Parameters:
//  SelectedPeriod - Date - Selected period
//  AdditionalParameters - Arbitrary - advanced setting
&AtClient
Procedure SetGeneralPeriodCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		For Each CurrRow In BlockingChanges Do
			
			CurrentPeriod = Min(CurrRow.CanBeBlockedBy, SelectedPeriod);
			
			CurrRow.BlockedPeriod = CurrentPeriod;
			CurrRow.BlockedPeriodPresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(CurrentPeriod);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordPeriodLocks()
	
	For Each CurrRow In BlockingChanges Do
		
		If CurrRow.BlockedPeriod = CurrRow.SourcePeriod Then
			Continue;
		EndIf;
		
		RecordManager = InformationRegisters.SetUpLockFromChanges.CreateRecordManager();
		RecordManager.Organization = CurrRow.Organization;
		RecordManager.LockUntil = BegOfMonth(CurrRow.BlockedPeriod);
		
		If FormIsOpenContextually Then
			RecordManager.Comment = NStr("vi = 'Đã thiết lập từ biểu mẫu đóng tháng';
										|ru = 'Установлено из формы закрытия месяца';
										|en = 'Set from the month-end closing form'; fa = 'Set from the month-end closing form';
										|it = 'Установлено из формы закрытия месяца';
										|pl = 'Set from the month-end closing form';
										|tr = 'Ay sonu kapanış formundan ayarlandı'");
		Else
			RecordManager.Comment = NStr("vi = 'Đã thiết lập từ biểu mẫu tùy chỉnh phong tỏa';
										|ru = 'Установлено из формы настройки блокировки';
										|en = 'Set from the lock setup form'; fa = 'Set from the lock setup form';
										|it = 'Установлено из формы настройки блокировки';
										|pl = 'Set from the lock setup form';
										|tr = 'Kilit ayar formundan ayarlandı'");
		EndIf;
		
		RecordManager.Write(True);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Incorrect period set (more than the maximum allowed)
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BlockingFromChangesBlockedPeriod.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("BlockingChanges.BlockedPeriod");
	ItemFilter.RightValue  = New DataCompositionField("BlockingChanges.CanBeBlockedBy");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// The blocking period has been changed
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BlockingFromChangesBlockedPeriod.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("BlockingChanges.BlockedPeriod");
	ItemFilter.RightValue  = New DataCompositionField("BlockingChanges.SourcePeriod");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
EndProcedure

#EndRegion
