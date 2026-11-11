#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("ShipIfAvailable") Then
		
		StandardProcessing = False;
		
		Result = SupplyInDocumentsServerCall.ProcessingOfDataAcquisitionOfSoftwareOptionSelection(Parameters);
		
		Package = Parameters.Package;
		If Not ValueIsFilled(Package) Then
			If ValueIsFilled(Result.UnitOfMeasure) Then
				Package = Result.UnitOfMeasure;
			EndIf;
		EndIf;
		
		YouNeedToSpecifySeriesInLine = Result.YouNeedToSpecifySeriesInLine;
		WarehouseSelectionRequired = Parameters.Property("MultipleWarehouses")
			And Parameters.MultipleWarehouses
			And (Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
				Or Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		
		ReserveOrShipment = Parameters.SupplyOption
				= PredefinedValue("Enum.SupplyOptions.FromWarehouse")
			Or Parameters.SupplyOption
				= PredefinedValue("Enum.SupplyOptions.Ship");
		
		SplittingLinesIsAllowed = Not Parameters.Property("UsePartialShipment")
			Or Parameters.UsePartialShipment;
		
		ChoiceData = New ValueList();
		
		Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
		Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
		ChoiceData.Add(Value, NStr("vi = 'Không đảm bảo';
									|ru = 'Не обеспечивать';
									|en = 'Do not supply'; fa = 'تأمین نشود';
									|it = 'Non approvvigionare';
									|pl = 'Nie zapewniać';
									|tr = 'Tedarik etme'"));
		
		Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
		Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply");
		ChoiceData.Add(Value, NStr("vi = 'Cần đảm bảo';
									|ru = 'К обеспечению';
									|en = 'To supply'; fa = 'برای تأمین';
									|it = 'Da approvvigionare';
									|pl = 'Do zapełnienia';
									|tr = 'Tedarik edilecek'"));
		
		Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
		Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.ReserveAsReceived");
		ChoiceData.Add(Value, NStr("vi = 'Dự phòng theo phương thức tiếp nhận';
									|ru = 'Резервировать по мере поступления';
									|en = 'Reserve upon receipt'; fa = 'رزرو هنگام دریافت';
									|it = 'Prenotare in base agli arrivi';
									|pl = 'Zarezerwuj w miarę otrzymania';
									|tr = 'Geldikçe rezerve et'"));
		
		If Parameters.NumberOfPackages > 0 Then
			
			If Parameters.SupplyOption = PredefinedValue("Enum.SupplyOptions.TransferedEarlier")
					Or ReserveOrShipment
					Or Not Parameters.ShipIfAvailable
					Or Result.PostWithoutReserveControl
						And Not SplittingLinesIsAllowed
					Or Parameters.NumberOfPackages <= Parameters.Available
					Or Result.AllowableVariance > 0
						And Parameters.Count * Result.PackagingFactor <= Parameters.Available Then
				
				Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
				Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
				ChoiceData.Add(Value, NStr("vi = 'Dự phòng trong kho (tất cả)';
											|ru = 'Резервировать на складе (все)';
											|en = 'Reserve at warehouse (all)'; fa = 'Reserve at warehouse (all)';
											|it = 'Prenotare in magazzino (tutto)';
											|pl = 'Rezerwuj w magazynie (wszystkie)';
											|tr = 'Ambarda rezerv et (tümü)'"));
				
				Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
				Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
				ChoiceData.Add(Value, NStr("vi = 'Giao hàng (tất cả)';
											|ru = 'Отгрузить (все)';
											|en = 'Ship (all)'; fa = 'Ship (all)';
											|it = 'Spedire (tutto)';
											|pl = 'Wyślij (wszystkie)';
											|tr = 'Sevk et (tümü)'"));
				
				If YouNeedToSpecifySeriesInLine Or WarehouseSelectionRequired Then
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
					Value.OpenWarehouseAndSeriesSelectionForm = True;
					ChoiceData.Add(Value, NStr("vi = 'Dự phòng trong kho ...';
												|ru = 'Резервировать на складе ...';
												|en = 'Reserve at warehouse ...'; fa = 'رزرو در انبار ...';
												|it = 'Prenotare in magazzino ...';
												|pl = 'Rezerwuj w magazynie ...';
												|tr = 'Ambarda rezerve et ...'"));
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
					Value.OpenWarehouseAndSeriesSelectionForm = True;
					ChoiceData.Add(Value, NStr("vi = 'Giao hàng ...';
												|ru = 'Отгрузить ...';
												|en = 'Ship ...'; fa = 'Ship ...';
												|it = 'Da spedire ...';
												|pl = 'Wyślij ...';
												|tr = 'Sevk et ...'"));
					
				ElsIf SplittingLinesIsAllowed Then
					
					If Not ReserveOrShipment Then
						Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
						Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
						Value.OpenLineSplittingForm = True;
						Value.AvailableQuantityWhenSplittingLine = Parameters.NumberOfPackages;
						Value.AcceptableDeviationOnChoiceSupplyOption = Result.AllowableVariance;
						Value.TotalNumberWhenSplittingLine = Parameters.NumberOfPackages;
						ChoiceData.Add(Value, NStr("vi = 'Dự phòng trong kho ...';
													|ru = 'Резервировать на складе ...';
													|en = 'Reserve at warehouse ...'; fa = 'رزرو در انبار ...';
													|it = 'Prenotare in magazzino ...';
													|pl = 'Rezerwuj w magazynie ...';
													|tr = 'Ambarda rezerve et ...'"));
					EndIf;
					
					If Parameters.SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship") Then
						Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
						Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
						Value.OpenLineSplittingForm = True;
						Value.AvailableQuantityWhenSplittingLine = Parameters.NumberOfPackages;
						Value.AcceptableDeviationOnChoiceSupplyOption = Result.AllowableVariance;
						Value.TotalNumberWhenSplittingLine = Parameters.NumberOfPackages;
						ChoiceData.Add(Value, NStr("vi = 'Giao hàng ...';
													|ru = 'Отгрузить ...';
													|en = 'Ship ...'; fa = 'Ship ...';
													|it = 'Da spedire ...';
													|pl = 'Wyślij ...';
													|tr = 'Sevk et ...'"));
					EndIf;
					
				EndIf;
				
			Else
				
				If SplittingLinesIsAllowed And Parameters.Available > 0 Then
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
					Value.SplitRow = True;
					
					Text = NStr("vi = 'Dự phòng trong kho: %1 %2';
								|ru = 'Резервировать на складе: %1 %2';
								|en = 'Reserve at warehouse: %1 %2'; fa = 'Reserve at warehouse: %1 %2';
								|it = 'Prenotare in magazzino: %1 %2';
								|pl = 'Rezerwacja na magazynie: %1 %2';
								|tr = 'Ambarda rezerve et: %1 %2'");
					Text = StrTemplate(Text, Format(Parameters.Available, "NFD=3"), Package);
					
					ChoiceData.Add(Value, Text);
					
				EndIf;
				
				If SplittingLinesIsAllowed And Parameters.Available > 0 Then
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
					Value.SplitRow = True;
					
					Text = NStr("vi = 'Giao hàng: %1 %2';
								|ru = 'Отгрузить: %1 %2';
								|en = 'Ship: %1 %2'; fa = 'Ship: %1 %2';
								|it = 'Spedire: %1 %2';
								|pl = 'Wyślij: %1 %2';
								|tr = 'Sevk et: %1 %2'");
					Text = StrTemplate(Text, Format(Parameters.Available, "NFD=3"), Package);
					
					ChoiceData.Add(Value, Text);
					
				EndIf;
				
				If WarehouseSelectionRequired Then
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
					Value.OpenWarehouseAndSeriesSelectionForm = True;
					ChoiceData.Add(Value, NStr("vi = 'Dự phòng trong kho ...';
												|ru = 'Резервировать на складе ...';
												|en = 'Reserve at warehouse ...'; fa = 'رزرو در انبار ...';
												|it = 'Prenotare in magazzino ...';
												|pl = 'Rezerwuj w magazynie ...';
												|tr = 'Ambarda rezerve et ...'"));
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
					Value.OpenWarehouseAndSeriesSelectionForm = True;
					ChoiceData.Add(Value, NStr("vi = 'Giao hàng ...';
												|ru = 'Отгрузить ...';
												|en = 'Ship ...'; fa = 'Ship ...';
												|it = 'Da spedire ...';
												|pl = 'Wyślij ...';
												|tr = 'Sevk et ...'"));
					
				ElsIf SplittingLinesIsAllowed And YouNeedToSpecifySeriesInLine And Parameters.Available > 0 Then
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
					Value.OpenWarehouseAndSeriesSelectionForm = True;
					ChoiceData.Add(Value, NStr("vi = 'Dự phòng trong kho ...';
												|ru = 'Резервировать на складе ...';
												|en = 'Reserve at warehouse ...'; fa = 'رزرو در انبار ...';
												|it = 'Prenotare in magazzino ...';
												|pl = 'Rezerwuj w magazynie ...';
												|tr = 'Ambarda rezerve et ...'"));
					
					Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
					Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
					Value.OpenWarehouseAndSeriesSelectionForm = True;
					ChoiceData.Add(Value, NStr("vi = 'Giao hàng ...';
												|ru = 'Отгрузить ...';
												|en = 'Ship ...'; fa = 'Ship ...';
												|it = 'Da spedire ...';
												|pl = 'Wyślij ...';
												|tr = 'Sevk et ...'"));
					
				ElsIf (Parameters.Available > 0 Or Result.PostWithoutReserveControl)
					And SplittingLinesIsAllowed Then
					
					If Not ReserveOrShipment Then
						Available = ?(Result.PostWithoutReserveControl, Parameters.NumberOfPackages, Parameters.Available);
						Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
						Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
						Value.OpenLineSplittingForm = True;
						Value.AvailableQuantityWhenSplittingLine = Available;
						Value.AcceptableDeviationOnChoiceSupplyOption = Result.AllowableVariance;
						Value.TotalNumberWhenSplittingLine = Parameters.NumberOfPackages;
						ChoiceData.Add(Value, NStr("vi = 'Dự phòng trong kho ...';
													|ru = 'Резервировать на складе ...';
													|en = 'Reserve at warehouse ...'; fa = 'رزرو در انبار ...';
													|it = 'Prenotare in magazzino ...';
													|pl = 'Rezerwuj w magazynie ...';
													|tr = 'Ambarda rezerve et ...'"));
					EndIf;
					
					If Parameters.SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship")
							And Parameters.Available > 0 Then
						Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
						Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
						Value.OpenLineSplittingForm = True;
						Value.AvailableQuantityWhenSplittingLine = ?(Result.PostWithoutReserveControl,
							Parameters.NumberOfPackages,
							Parameters.Available);
						Value.AcceptableDeviationOnChoiceSupplyOption = Result.AllowableVariance;
						Value.TotalNumberWhenSplittingLine = Parameters.NumberOfPackages;
						ChoiceData.Add(Value, NStr("vi = 'Giao hàng ...';
													|ru = 'Отгрузить ...';
													|en = 'Ship ...'; fa = 'Ship ...';
													|it = 'Da spedire ...';
													|pl = 'Wyślij ...';
													|tr = 'Sevk et ...'"));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		Value = ProvisionInDocumentsClientServer.ValueOfChoosingSecurityOption();
		Value.SupplyOption = PredefinedValue("Enum.SupplyOptions.TransferedEarlier");
		ChoiceData.Add(Value, NStr("vi = 'Đã chuyển giao từ trước';
									|ru = 'Передан ранее';
									|en = 'Transferred earlier'; fa = 'منتقل‌شده قبلی';
									|it = 'Trasferito precedentemente';
									|pl = 'Przekazano wcześniej';
									|tr = 'Daha önce transfer edildi'"));
		
		AllowedActions = New Array();
		
		If Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
				Or Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
				
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.TransferedEarlier"));
				
		ElsIf Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
					Or Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
						And Not Parameters.WithAssignment Then
				
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
				
		ElsIf Parameters.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
				AllowedActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
				
		EndIf;
		
		If Parameters.Property("AllowedActions") Then
			AcceptableActionsInDocument = Parameters.AllowedActions;
		Else
			AcceptableActionsInDocument = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
		EndIf;
		
		ItemCount = ChoiceData.Count();
		For Counter = 1 To ItemCount Do
			
			CurrentAction1 = ChoiceData[ItemCount - Counter].Value.SupplyOption;
			If AllowedActions.Find(CurrentAction1) = Undefined
					Or AcceptableActionsInDocument.Find(CurrentAction1) = Undefined Then
				
				ChoiceData.Delete(ChoiceData[ItemCount - Counter]);
				
			EndIf;
			
		EndDo;
	
	Else
		
		StandardProcessing = False;
		ChoiceData = New ValueList();
		ChoiceData.Add(Enums.SupplyOptions.Ship);
		ChoiceData.Add(Enums.SupplyOptions.FromWarehouse);
		ChoiceData.Add(Enums.SupplyOptions.ReserveAsReceived);
		ChoiceData.Add(Enums.SupplyOptions.ToSupply);
		ChoiceData.Add(Enums.SupplyOptions.NotRequired);
		ChoiceData.Add(Enums.SupplyOptions.TransferedEarlier);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

#EndIf