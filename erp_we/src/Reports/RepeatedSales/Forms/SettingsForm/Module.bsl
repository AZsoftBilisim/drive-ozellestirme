#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RestoreSettings();
	SetMode();
	
	If Not GetFunctionalOption("UsePartnersSegments") Then
		CustomerSegmentUsage = False;
		Items.GroupCustomerSegment.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseProductSegments") Then
		ItemSegmentUsage = False;
		Items.GroupProductSegment.Visible = False;
	EndIf;

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExtendedModeOnChange(Item)

	SetMode();
	
EndProcedure

&AtClient
Procedure ActiveUpToOnChange(Item)
	
	FallingAsleepFrom = ActiveUpTo; 
	Values = New Structure("FallingAsleepFrom",FallingAsleepFrom);
	Items.SceneryFallingAsleepFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepFrom] đến';
																										|ru = 'от [FallingAsleepFrom] до';
																										|en = 'from [FallingAsleepFrom] to'; fa = 'from [FallingAsleepFrom] to';
																										|it = 'dal [FallingAsleepFrom] al';
																										|pl = 'od [FallingAsleepFrom] do';
																										|tr = 'başlangıcı [FallingAsleepFrom] bitişi'"), Values);
	
	If ExtendedMode = 0 Then
		FallingAsleepPerspectiveFrom = ActiveUpTo+1;
		FallingAsleepFaithfulFrom = ActiveUpTo+1;	
		Values = New Structure("FallingAsleepPerspectiveFrom, FallingAsleepFaithfulFrom",FallingAsleepPerspectiveFrom,FallingAsleepFaithfulFrom);
		Items.SceneryFallingAsleepPerspectiveFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepPerspectiveFrom] đến';
																														|ru = 'от [FallingAsleepPerspectiveFrom] до';
																														|en = 'from [FallingAsleepPerspectiveFrom] to'; fa = 'from [FallingAsleepPerspectiveFrom] to';
																														|it = 'dal [FallingAsleepPerspectiveFrom] al';
																														|pl = 'od [FallingAsleepPerspectiveFrom] do';
																														|tr = 'başlangıcı [FallingAsleepPerspectiveFrom] bitişi'"), Values);
		Items.SceneryFallingAsleepPerspectiveFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepFaithfulFrom] đến';
																														|ru = 'от [FallingAsleepFaithfulFrom] до';
																														|en = 'from [FallingAsleepFaithfulFrom] to'; fa = 'from [FallingAsleepFaithfulFrom] to';
																														|it = 'da [FallingAsleepFaithfulFrom] a';
																														|pl = 'od [FallingAsleepFaithfulFrom] do';
																														|tr = 'başlangıcı [FallingAsleepFaithfulFrom] bitişi'"), Values);
	EndIf;
			
EndProcedure

&AtClient
Procedure ActiveProspectiveUpToOnChange(Item)
	
	FallingAsleepPerspectiveFrom = ActiveProspectiveUpTo;
	Values = New Structure("FallingAsleepPerspectiveFrom",FallingAsleepPerspectiveFrom);
	Items.SceneryFallingAsleepPerspectiveFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepPerspectiveFrom] đến';
																													|ru = 'от [FallingAsleepPerspectiveFrom] до';
																													|en = 'from [FallingAsleepPerspectiveFrom] to'; fa = 'from [FallingAsleepPerspectiveFrom] to';
																													|it = 'dal [FallingAsleepPerspectiveFrom] al';
																													|pl = 'od [FallingAsleepPerspectiveFrom] do';
																													|tr = 'başlangıcı [FallingAsleepPerspectiveFrom] bitişi'"), Values);
	
EndProcedure

&AtClient
Procedure ActiveLoyalToOnChange(Item)
	
	FallingAsleepFaithfulFrom = ActiveLoyalTo;
	Values = New Structure("FallingAsleepFaithfulFrom",FallingAsleepFaithfulFrom);
	Items.SceneryFallingAsleepFaithfulFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepFaithfulFrom] đến';
																												|ru = 'от [FallingAsleepFaithfulFrom] до';
																												|en = 'from [FallingAsleepFaithfulFrom] to'; fa = 'from [FallingAsleepFaithfulFrom] to';
																												|it = 'da [FallingAsleepFaithfulFrom] a';
																												|pl = 'od [FallingAsleepFaithfulFrom] do';
																												|tr = 'başlangıcı [FallingAsleepFaithfulFrom] bitişi'"), Values);
	
EndProcedure

&AtClient
Procedure FallingAsleepBeforeOnChange(Item)
			
	Sleepers = FallingAsleepBefore; 
	
	If ExtendedMode = 0 Then
		SleepingProspects = FallingAsleepBefore;
		SleepingFaithful = FallingAsleepBefore;	
	EndIf;
	
EndProcedure

&AtClient
Procedure FallingAsleepPromisingUpToOnChange(Item)
	
	SleepingProspects = FallingAsleepPromisingUpTo;
	
EndProcedure

&AtClient
Procedure FallingAsleepFaithfulToOnChange(Item)
	
	SleepingFaithful = FallingAsleepFaithfulTo;
	
EndProcedure

&AtClient
Procedure PurchasesArePromisingUpToOnChange(Item)
	
	PurchasesAreCorrect = PurchasesArePromisingUpTo;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationUsage = True;
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	ManagerUsage = True;
	
EndProcedure

&AtClient
Procedure AmountOfPurchasesOnChange(Item)
	
	PurchaseAmountUsage = True;

EndProcedure

&AtClient
Procedure CustomerSegmentOnChange(Item)
	
	CustomerSegmentUsage = True;
	
EndProcedure

&AtClient
Procedure ProductSegmentOnChange(Item)
	
	ItemSegmentUsage = True;
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	NomenclatureUsage = True;

EndProcedure

&AtClient
Procedure BeginningDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodOfUse = True;

EndProcedure

&AtClient
Procedure EndingDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodOfUse = True;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	CheckTheMode();
	
	CheckSelections();

	If Not IntervalsAreCorrect() Then
		Return;
	EndIf;
	
	AttributesToSaveNames =
		"Organization,OrganizationUsage,
		|Manager,ManagerUsage,Period,
		|StartDate,EndDate,PeriodOfUse,
		|ActiveLoyalTo,ActiveUpTo,ActiveProspectiveUpTo,
		|FallingAsleepFaithfulTo,FallingAsleepFaithfulFrom,FallingAsleepBefore,FallingAsleepFrom,
		|FallingAsleepPromisingUpTo,FallingAsleepPerspectiveFrom,
		|CustomersNumbersPercentages,DisplayLabelsForArrows,
		|Products,NomenclatureUsage,DisplayArrows,
		|PurchasesAreCorrect,NewPurchases,PurchasesArePromisingUpTo,ProspectivePurchasesFrom,
		|ExtendedMode,Potential,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage,
		|Sleepers,SleepingFaithful,SleepingProspects";

	AddlParameters = New Structure(AttributesToSaveNames);
	FillPropertyValues(AddlParameters, ThisForm);

	Close(AddlParameters);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ValueSelected) Then
		PeriodOfUse = False;
		StartDate = Undefined;
		EndDate = Undefined;
	Else
		
	PeriodOfUse = True;

	Period = ValueSelected;
	StartDate = Date("20130724");
	StartDate = Period.StartDate;
	EndDate = Period.EndDate;
	
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RestoreSettings()
	
	Attributes = GetAttributes();
	For Each Attribute In Attributes Do		
		If Not Parameters.Property(Attribute.Name) Then
			Continue;
		EndIf;
		If Attribute.Name = "StartDate" Then	
			Period.StartDate = Parameters[Attribute.Name];
			ThisForm[Attribute.Name] = Parameters[Attribute.Name];
			Continue;	
		EndIf;
		If Attribute.Name = "EndDate" Then				
			Period.EndDate = Parameters[Attribute.Name];
			ThisForm[Attribute.Name] = Parameters[Attribute.Name];
			Continue;	
		EndIf;
		ThisForm[Attribute.Name] = Parameters[Attribute.Name];
	EndDo;
	Currency = Constants.ManagementAccountingCurrency.Get();
	Items.DecorationCurrency.Title = Currency;
	
EndProcedure

&AtServer
Procedure SetMode()

	If ExtendedMode = 0 Then
		Items.GroupDaysPerspective.Visible = False;
		Items.GroupDaysTrue.Visible = False;
		Items.NewDecorations.Visible = False;
		Items.Decoration1.Visible = False;
		Items.DecorationActive.Font = New Font(,,,False);
		Items.SceneryFallingAsleep.Font = New Font(,,,False);
		Items.ScenerySleepers.Font = New Font(,,,False);
	Else
		Items.GroupDaysPerspective.Visible = True;
		Items.GroupDaysTrue.Visible = True;
		Items.NewDecorations.Visible = True;
		Items.Decoration1.Visible = True;
		Items.DecorationActive.Font = New Font(,,True);
		Items.SceneryFallingAsleep.Font = New Font(,,True);
		Items.ScenerySleepers.Font = New Font(,,True);

			
		Values = New Structure("FallingAsleepFrom, FallingAsleepPerspectiveFrom, FallingAsleepFaithfulFrom",FallingAsleepFrom,FallingAsleepPerspectiveFrom,FallingAsleepFaithfulFrom);
		Items.SceneryFallingAsleepFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepFrom] đến';
																											|ru = 'от [FallingAsleepFrom] до';
																											|en = 'from [FallingAsleepFrom] to'; fa = 'from [FallingAsleepFrom] to';
																											|it = 'dal [FallingAsleepFrom] al';
																											|pl = 'od [FallingAsleepFrom] do';
																											|tr = 'başlangıcı [FallingAsleepFrom] bitişi'"), Values);
		Items.SceneryFallingAsleepPerspectiveFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepPerspectiveFrom] đến';
																														|ru = 'от [FallingAsleepPerspectiveFrom] до';
																														|en = 'from [FallingAsleepPerspectiveFrom] to'; fa = 'from [FallingAsleepPerspectiveFrom] to';
																														|it = 'dal [FallingAsleepPerspectiveFrom] al';
																														|pl = 'od [FallingAsleepPerspectiveFrom] do';
																														|tr = 'başlangıcı [FallingAsleepPerspectiveFrom] bitişi'"), Values);
		Items.SceneryFallingAsleepFaithfulFrom.Title = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'từ [FallingAsleepFaithfulFrom] đến';
																													|ru = 'от [FallingAsleepFaithfulFrom] до';
																													|en = 'from [FallingAsleepFaithfulFrom] to'; fa = 'from [FallingAsleepFaithfulFrom] to';
																													|it = 'da [FallingAsleepFaithfulFrom] a';
																													|pl = 'od [FallingAsleepFaithfulFrom] do';
																													|tr = 'başlangıcı [FallingAsleepFaithfulFrom] bitişi'"), Values);
	EndIf;	

EndProcedure

&AtClient
Procedure CheckTheMode()
	
	If ExtendedMode = 0 Then
		ActiveProspectiveUpTo = ActiveUpTo;
		ActiveLoyalTo = ActiveUpTo; 
		FallingAsleepPerspectiveFrom = ActiveUpTo;
		FallingAsleepFaithfulFrom = ActiveUpTo;
		FallingAsleepPromisingUpTo = FallingAsleepBefore;
		FallingAsleepFaithfulTo = FallingAsleepBefore; 
		SleepingProspects = FallingAsleepBefore;
		SleepingFaithful = FallingAsleepBefore;	
	EndIf;

EndProcedure

&AtClient
Function IntervalsAreCorrect()
	
	IntervalsAreCorrect = True;
	
	If ActiveUpTo = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Đã đặt sai khoảng ngày.';
										|ru = 'Некорректно задан интервал дней.';
										|en = 'Incorrect interval of days.'; fa = 'Incorrect interval of days.';
										|it = 'Intervallo di giorni indicato non correttamente.';
										|pl = 'Interwał dni jest zadany niepoprawnie.';
										|tr = 'Gün aralığı yanlış girildi.'"),,"ActiveUpTo");
		IntervalsAreCorrect = False;
	EndIf;
	
	If ActiveProspectiveUpTo = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Đã đặt sai khoảng ngày.';
										|ru = 'Некорректно задан интервал дней.';
										|en = 'Incorrect interval of days.'; fa = 'Incorrect interval of days.';
										|it = 'Intervallo di giorni indicato non correttamente.';
										|pl = 'Interwał dni jest zadany niepoprawnie.';
										|tr = 'Gün aralığı yanlış girildi.'"),,"ActiveProspectiveUpTo");
		IntervalsAreCorrect = False;
	EndIf;
	
	If ActiveLoyalTo = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Đã đặt sai khoảng ngày.';
										|ru = 'Некорректно задан интервал дней.';
										|en = 'Incorrect interval of days.'; fa = 'Incorrect interval of days.';
										|it = 'Intervallo di giorni indicato non correttamente.';
										|pl = 'Interwał dni jest zadany niepoprawnie.';
										|tr = 'Gün aralığı yanlış girildi.'"),,"ActiveLoyalTo");
		IntervalsAreCorrect = False;
	EndIf;
	
	If FallingAsleepBefore < FallingAsleepFrom Then
		CommonClient.MessageToUser(NStr("vi = 'Đã đặt sai khoảng ngày.';
										|ru = 'Некорректно задан интервал дней.';
										|en = 'Incorrect interval of days.'; fa = 'Incorrect interval of days.';
										|it = 'Intervallo di giorni indicato non correttamente.';
										|pl = 'Interwał dni jest zadany niepoprawnie.';
										|tr = 'Gün aralığı yanlış girildi.'"),,"FallingAsleepBefore");
		IntervalsAreCorrect = False;
	EndIf;

	If FallingAsleepPromisingUpTo < FallingAsleepPerspectiveFrom Then
		CommonClient.MessageToUser(NStr("vi = 'Đã đặt sai khoảng ngày.';
										|ru = 'Некорректно задан интервал дней.';
										|en = 'Incorrect interval of days.'; fa = 'Incorrect interval of days.';
										|it = 'Intervallo di giorni indicato non correttamente.';
										|pl = 'Interwał dni jest zadany niepoprawnie.';
										|tr = 'Gün aralığı yanlış girildi.'"),,"FallingAsleepPromisingUpTo");
		IntervalsAreCorrect = False;
	EndIf;

	If FallingAsleepFaithfulTo < FallingAsleepFaithfulFrom Then
		CommonClient.MessageToUser(NStr("vi = 'Đã đặt sai khoảng ngày.';
										|ru = 'Некорректно задан интервал дней.';
										|en = 'Incorrect interval of days.'; fa = 'Incorrect interval of days.';
										|it = 'Intervallo di giorni indicato non correttamente.';
										|pl = 'Interwał dni jest zadany niepoprawnie.';
										|tr = 'Gün aralığı yanlış girildi.'"),,"FallingAsleepFaithfulTo");
		IntervalsAreCorrect = False;
	EndIf;

	Return IntervalsAreCorrect;

EndFunction

&AtClient
Procedure CheckSelections()
	
	If PeriodOfUse = True Then
		If Not ValueIsFilled(StartDate) Or Not ValueIsFilled(EndDate) Then
			PeriodOfUse = False;
		EndIf;
	EndIf;
	
	If OrganizationUsage = True Then
		If Not ValueIsFilled(Organization) Then
			OrganizationUsage = False;
		EndIf;
	EndIf;
	
	If ManagerUsage = True Then
		If Not ValueIsFilled(Manager) Then
			ManagerUsage = False;
		EndIf;
	EndIf;
	
	If PurchaseAmountUsage = True Then
		If Not ValueIsFilled(AmountOfPurchases) Then
			PurchaseAmountUsage = False;
		EndIf;
	EndIf;

	If CustomerSegmentUsage = True Then
		If Not ValueIsFilled(CustomerSegment) Then
			CustomerSegmentUsage = False;
		EndIf;
	EndIf;

	If ItemSegmentUsage = True Then
		If Not ValueIsFilled(ProductSegment) Then
			ItemSegmentUsage = False;
		EndIf;
	EndIf;

	If NomenclatureUsage = True Then
		If Not ValueIsFilled(Products) Then
			NomenclatureUsage = False;
		EndIf;
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
	If Item.Name = "sh_ShamsiInput_F_StartDate" Then
		BeginningDateOfPeriodOnChange(Items.BeginningDateOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndDate" Then
		EndingDateOfPeriodOnChange(Items.EndingDateOfPeriod);
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
