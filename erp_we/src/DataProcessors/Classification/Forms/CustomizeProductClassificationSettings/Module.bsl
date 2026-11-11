
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	TimeIntervals.Add(Enums.Periodicity.Day);
	TimeIntervals.Add(Enums.Periodicity.Week);
	TimeIntervals.Add(Enums.Periodicity.TenDays);
	TimeIntervals.Add(Enums.Periodicity.Month);
	TimeIntervals.Add(Enums.Periodicity.Quarter);
	TimeIntervals.Add(Enums.Periodicity.HalfYear);
	TimeIntervals.Add(Enums.Periodicity.Year);
	
	UseRevenueClassification = Constants.UseABCXYZClassificationOfInventoryByRevenue.Get();
	UseGrossProfitClassification = Constants.UseABCXYZClassificationOfInventoryByGrossProfit.Get();
	UseClassificationByNumberOfSales = Constants.UseABCXYZClassificationOfInventoryByNumberOfSales.Get();
	ABCLassificationPeriod = Constants.PeriodOfABCClassificationOfInventory.Get();
	NumberOfABCLassificationPeriods = Constants.NumberOfPeriodsOfABCClassificationOfInventory.Get();
	XYZClassificationPeriod = Constants.PeriodOfXYZClassificationOfInventory.Get();
	NumberOfXYZClassificationPeriods = Constants.NumberOfPeriodsOfXYZClassificationOfInventory.Get();
	XyzclassificationSubperiod = Constants.SubperiodOfXYZClassificationOfInventory.Get();
	RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory = Constants.RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory.Get();
	RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory = Constants.RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory.Get();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailableSubperiodValues(Items.XyzclassificationSubperiod, XYZClassificationPeriod);
	
	Items.TheDecorationsAmsclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																				|ru = 'По данным за период: %1.';
																				|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																				|it = 'Secondo i dati per il periodo: %1.';
																				|pl = 'Według danych za okres: %1.';
																				|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(ABCLassificationPeriod, NumberOfABCLassificationPeriods));
	Items.DecorationXyzclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																			|ru = 'По данным за период: %1.';
																			|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																			|it = 'Secondo i dati per il periodo: %1.';
																			|pl = 'Według danych za okres: %1.';
																			|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(XYZClassificationPeriod, NumberOfXYZClassificationPeriods, XyzclassificationSubperiod));
	Items.DecorationTakeIntoAccountTheRulesOfInternalProductMovementWhenClassifyingTheNomenclature.Enabled = RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory;
	Items.DecorationTakeIntoAccountTheRulesOfInternalProductMovementWhenXyzclassingTheNomenclature.Enabled = RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ABCLassificationPeriodOnChange(Item)
	
	Items.TheDecorationsAmsclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																				|ru = 'По данным за период: %1.';
																				|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																				|it = 'Secondo i dati per il periodo: %1.';
																				|pl = 'Według danych za okres: %1.';
																				|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(ABCLassificationPeriod, NumberOfABCLassificationPeriods));
	
EndProcedure

&AtClient
Procedure NumberOfABCLassificationPeriodsOnChange(Item)
	
	Items.TheDecorationsAmsclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																				|ru = 'По данным за период: %1.';
																				|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																				|it = 'Secondo i dati per il periodo: %1.';
																				|pl = 'Według danych za okres: %1.';
																				|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(ABCLassificationPeriod, NumberOfABCLassificationPeriods));
	
EndProcedure

&AtClient
Procedure RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventoryOnChange(Item)
	
	Items.DecorationTakeIntoAccountTheRulesOfInternalProductMovementWhenClassifyingTheNomenclature.Enabled = RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory;
	
EndProcedure

&AtClient
Procedure XYZClassificationPeriodOnChange(Item)
	
	SetAvailableSubperiodValues(Items.XyzclassificationSubperiod, XYZClassificationPeriod);
	
	Items.DecorationXyzclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																			|ru = 'По данным за период: %1.';
																			|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																			|it = 'Secondo i dati per il periodo: %1.';
																			|pl = 'Według danych za okres: %1.';
																			|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(XYZClassificationPeriod, NumberOfXYZClassificationPeriods, XyzclassificationSubperiod));

EndProcedure

&AtClient
Procedure NumberOfXYZClassificationPeriodsOnChange(Item)
	
	Items.DecorationXyzclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1';
																			|ru = 'По данным за период: %1';
																			|en = 'According to data for the period:%1'; fa = 'According to data for the period:%1';
																			|it = 'Per i dati per il periodo: %1';
																			|pl = 'Według danych okresu: %1';
																			|tr = 'Dönem verilerine göre: %1'"),
		SupplyClientServer.SettingDetails(XYZClassificationPeriod, NumberOfXYZClassificationPeriods, XyzclassificationSubperiod));
	
EndProcedure

&AtClient
Procedure XyzclassificationSubperiodOnChange(Item)
	
	Items.DecorationXyzclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																			|ru = 'По данным за период: %1.';
																			|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																			|it = 'Secondo i dati per il periodo: %1.';
																			|pl = 'Według danych za okres: %1.';
																			|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(XYZClassificationPeriod, NumberOfXYZClassificationPeriods, XyzclassificationSubperiod));
	
EndProcedure

&AtClient
Procedure RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventoryOnChange(Item)
	
	Items.DecorationTakeIntoAccountTheRulesOfInternalProductMovementWhenXyzclassingTheNomenclature.Enabled = RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If CheckFilling() Then
		
		SaveParameters();
		
		ReturnCode = New Structure;
		
		ReturnCode.Insert("UseRevenueClassification", UseRevenueClassification);
		ReturnCode.Insert("UseGrossProfitClassification", UseGrossProfitClassification);
		ReturnCode.Insert("UseClassificationByNumberOfSales", UseClassificationByNumberOfSales);
		ReturnCode.Insert("ABCLassificationPeriod", ABCLassificationPeriod);
		ReturnCode.Insert("NumberOfABCLassificationPeriods", NumberOfABCLassificationPeriods);
		ReturnCode.Insert("XYZClassificationPeriod", XYZClassificationPeriod);
		ReturnCode.Insert("NumberOfXYZClassificationPeriods", NumberOfXYZClassificationPeriods);
		ReturnCode.Insert("XyzclassificationSubperiod", XyzclassificationSubperiod);
		ReturnCode.Insert("RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory", RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory);
		ReturnCode.Insert("RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory", RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory);
		
		Close(ReturnCode);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure SetAvailableSubperiodValues(Item, SelectedPeriod)
	
	Item.ChoiceList.Clear();
		
	If ValueIsFilled(SelectedPeriod) Then
		
		For Each Period In TimeIntervals Do
		
			Item.ChoiceList.Add(Period.Value);
			
			If SelectedPeriod = Period.Value Then
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveParameters()
	
	// The constants are recorded in privileged mode.
	SetPrivilegedMode(True);
	
	Constants.UseABCXYZClassificationOfInventoryByRevenue.Set(UseRevenueClassification);
	Constants.UseABCXYZClassificationOfInventoryByGrossProfit.Set(UseGrossProfitClassification);
	Constants.UseABCXYZClassificationOfInventoryByNumberOfSales.Set(UseClassificationByNumberOfSales);
	Constants.PeriodOfABCClassificationOfInventory.Set(ABCLassificationPeriod);
	Constants.NumberOfPeriodsOfABCClassificationOfInventory.Set(NumberOfABCLassificationPeriods);
	Constants.PeriodOfXYZClassificationOfInventory.Set(XYZClassificationPeriod);
	Constants.NumberOfPeriodsOfXYZClassificationOfInventory.Set(NumberOfXYZClassificationPeriods);
	Constants.SubperiodOfXYZClassificationOfInventory.Set(XyzclassificationSubperiod);
	Constants.RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory.Set(RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory);
	Constants.RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory.Set(RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory);
	
	RefreshReusableValues();
	
	// Disabling the privileged mode.
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndRegion
