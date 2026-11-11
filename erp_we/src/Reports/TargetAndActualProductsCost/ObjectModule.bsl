
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);	
	Settings = SettingsComposer.GetSettings();
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "GroupVariance", NStr("vi = 'Tổng số';
																					|ru = 'Итого';
																					|en = 'Total'; fa = 'جمع کل';
																					|it = 'Totale';
																					|pl = 'Total';
																					|tr = 'Toplam'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineMaterial", NStr("vi = 'Nguyên vật liệu';
																					|ru = 'Материальные';
																					|en = 'Material'; fa = 'ماده';
																					|it = 'Materiali';
																					|pl = 'Material';
																					|tr = 'Malzeme'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineItemized", NStr("vi = 'Mục hàng';
																					|ru = 'Постатейные';
																					|en = 'Itemized'; fa = 'تفکیک‌شده';
																					|it = 'Dettagliati per voce';
																					|pl = 'Itemized';
																					|tr = 'Ayrıntılı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineLaborCosts", NStr("vi = 'Chi phí nhân công';
																						|ru = 'Трудозатраты';
																						|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
																						|it = 'Costi di manodopera';
																						|pl = 'Labor costs';
																						|tr = 'İş gücü maliyetleri'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineAddExpenses", NStr("vi = 'Chi phí bổ sung';
																						|ru = 'Доп. расходы';
																						|en = 'Additional expenses'; fa = 'هزینه‌های تکمیلی';
																						|it = 'Spese aggiuntive';
																						|pl = 'Rozchody dodatkowe';
																						|tr = 'Ek giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "RowOffBalance", NStr("vi = 'Ngoài bảng';
																					|ru = 'Забалансовая';
																					|en = 'Off-balance'; fa = 'خارج از ترازنامه';
																					|it = 'Fuori bilancio';
																					|pl = 'Off-balance';
																					|tr = 'Bilanço dışı'"));
	
	BatchAccountingParameterVersion22 = DataCompositionClientServer.GetParameter(SettingsComposer, "BatchAccountingVersion22");
	If BatchAccountingParameterVersion22 <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "BatchAccountingVersion22",
			CalculationOfCostCached.BatchAccountingVersion22());
	EndIf;
	
	ParameterDateOfTransitionToBatchAccountingVersion22 = DataCompositionClientServer.GetParameter(SettingsComposer, "DateOfMigrationToBatchAccounting22");
	If ParameterDateOfTransitionToBatchAccountingVersion22 <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "DateOfMigrationToBatchAccounting22",
			CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	EndIf;	
	
EndProcedure

#EndRegion

#EndIf