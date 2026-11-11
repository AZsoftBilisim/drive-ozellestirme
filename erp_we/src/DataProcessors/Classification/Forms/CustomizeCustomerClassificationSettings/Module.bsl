
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
	
	UseRevenueClassification = Constants.UseABCXYZClassificationOfPartnersByRevenue.Get();
	UseGrossProfitClassification = Constants.UseABCXYZClassificationOfPartnersByGrossProfit.Get();
	UseClassificationByNumberOfSales = Constants.UseABCXYZClassificationOfPartnersByNumberOfSales.Get();
	ABCLassificationPeriod = Constants.PeriodOfABCClassificationOfPartners.Get();
	NumberOfABCLassificationPeriods = Constants.NumberOfPeriodsOfABCClassificationOfPartners.Get();
	XYZClassificationPeriod = Constants.PeriodOfXYZClassificationOfPartners.Get();
	NumberOfXYZClassificationPeriods = Constants.NumberOfPeriodsOfXYZClassificationOfPartners.Get();
	XyzclassificationSubperiod = Constants.SubperiodOfXYZClassificationOfPartners.Get();

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
	
	Items.DecorationXyzclassificationDescription.Title = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
																			|ru = 'По данным за период: %1.';
																			|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
																			|it = 'Secondo i dati per il periodo: %1.';
																			|pl = 'Według danych za okres: %1.';
																			|tr = 'Dönem verilerine göre: %1.'"),
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
	
	Constants.UseABCXYZClassificationOfPartnersByRevenue.Set(UseRevenueClassification);
	Constants.UseABCXYZClassificationOfPartnersByGrossProfit.Set(UseGrossProfitClassification);
	Constants.UseABCXYZClassificationOfPartnersByNumberOfSales.Set(UseClassificationByNumberOfSales);
	Constants.PeriodOfABCClassificationOfPartners.Set(ABCLassificationPeriod);
	Constants.NumberOfPeriodsOfABCClassificationOfPartners.Set(NumberOfABCLassificationPeriods);
	Constants.PeriodOfXYZClassificationOfPartners.Set(XYZClassificationPeriod);
	Constants.NumberOfPeriodsOfXYZClassificationOfPartners.Set(NumberOfXYZClassificationPeriods);
	Constants.SubperiodOfXYZClassificationOfPartners.Set(XyzclassificationSubperiod);
	
	RefreshReusableValues();
	
	// Disabling the privileged mode.
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndRegion
