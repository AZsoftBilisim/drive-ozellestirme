// @strict-types

#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var QuestionWasAsked_; // Boolean

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BoldFont = StyleFonts.BoldFont;
	ColorGreen = StyleColors.SuccessResultColor;
	ColorRed = StyleColors.ResultIssueColor;
	UnitOfMeasureForWeight = String(Constants.UnitOfMeasureForWeight.Get());
	UnitOfMeasureForVolume = String(Constants.UnitOfMeasureForVolume.Get());
	
	TransportationJob = Parameters.TransportationJob;
	Vehicle_ = Parameters.Vehicle_;
	Weight = Parameters.TaskWeight;
	VolumeM3 = Parameters.TaskScope;
	
	VehicleDetails = GoodsDelivery.VehicleDetails(Vehicle_);
	FillPropertyValues(ThisObject, VehicleDetails);
	
	TitleWeight = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trọng lượng, %1';
																				|ru = 'Вес, %1';
																				|en = 'Weight, %1'; fa = 'Weight, %1';
																				|it = 'Peso, %1';
																				|pl = 'Waga, %1';
																				|tr = 'Ağırlık, %1'"),
		UnitOfMeasureForWeight);
	VolumeHeader = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'khối lượng %1';
																				|ru = 'Объем, %1';
																				|en = 'Volume, %1'; fa = 'Volume, %1';
																				|it = 'Volume, %1';
																				|pl = 'Objętość, %1';
																				|tr = 'Hacim, %1'"),
		UnitOfMeasureForVolume);
	Items.GoodsToDeliverWeight.Title = TitleWeight;
	Items.GoodsToDeliverVolumeM3.Title = VolumeHeader;
	
	If Parameters.DeliveryKind = Enums.DeliveryKinds.ToWarehouse Then
		Items.DisposalOfTheRecipient.Visible = False;
	Else
		Items.OrdersSender.Visible = False;
	EndIf;
	
	FlightPoint = New Array; // Array of FormattedString, String
	
	If ValueIsFilled(Vehicle_) Then
		FlightPoint.Add(New FormattedString(String(Vehicle_),,,, "ShowVehicle"));
	EndIf;
	If ValueIsFilled(Parameters.PlanTripStartTime) Then
		If ValueIsFilled(FlightPoint) Then
			FlightPoint.Add(", ");
		EndIf;
		FlightPoint.Add(Format(Parameters.PlanTripStartTime, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																	|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																	|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																	|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																	|pl = 'DF=''dd.MM.yyyy hh:mm''';
																	|tr = 'DF=''dd.MM.yyyyy HH:mm'''")));
	EndIf;
	
	If ValueIsFilled(TransportationJob) Then
		If ValueIsFilled(FlightPoint) Then
			FlightPoint.Add(", ");
		EndIf;
		FlightPoint.Add(Common.ObjectAttributeValue(TransportationJob, "Number"));
	EndIf;
	
	If FlightPoint.Count() > 0 Then
		
		FlightPoint.Insert(
			0,
			New FormattedString(NStr("vi = 'Chuyến hàng:';
									|ru = 'Рейс:';
									|en = 'Trip:'; fa = 'Trip:';
									|it = 'Tragitto:';
									|pl = 'Trip:';
									|tr = 'Sefer:'") + " ", StyleFonts.BoldFont));
		
	EndIf;
	
	If Parameters.Property("Address")
	   And ValueIsFilled(Parameters.Address) Then
		If FlightPoint.Count() > 0 Then
			FlightPoint.Add(Chars.LF);
		EndIf;
		FlightPoint.Add(New FormattedString(NStr("vi = 'Mục:';
												|ru = 'Пункт:';
												|en = 'Point:'; fa = 'نقطه:';
												|it = 'Punto:';
												|pl = 'Point:';
												|tr = 'Nokta:'") + " ", StyleFonts.BoldFont));
		FlightPoint.Add(Parameters.Address);
		If ValueIsFilled(Parameters.TimeFrom) Then
			TimePattern = NStr("vi = 'từ %TimeFrom% đến %TimeTo%';
								|ru = 'с %TimeFrom% по %TimeTo%';
								|en = 'from %TimeFrom% to %TimeTo%'; fa = 'from %TimeFrom% to %TimeTo%';
								|it = 'dalle %TimeFrom% alle %TimeTo%';
								|pl = 'z %TimeFrom% do %TimeTo%';
								|tr = '%TimeFrom% itibaren %TimeTo% kadar'");
			If BegOfDay(Parameters.TimeFrom) = BegOfDay(Parameters.PlanTripStartTime) Then
				If BegOfDay(Parameters.TimeFrom) = BegOfDay(Parameters.TimeTo) Then
					Text = StrReplace(TimePattern, "%TimeFrom%", Format(Parameters.TimeFrom, NStr("vi = 'ДФ=''ЧЧ:мм''';
																									|ru = 'ДФ=''HH:mm''';
																									|en = 'DF=''HH:mm'''; fa = 'DF=''HH:mm''';
																									|it = 'ДФ= ''ЧЧ:мм''';
																									|pl = 'DF=''NN:mm''';
																									|tr = 'DF=''HH:mm'''")));
					Text = StrReplace(Text, "%TimeTo%", Format(Parameters.TimeTo, NStr("vi = 'ДФ=''ЧЧ:мм''';
																						|ru = 'ДФ=''HH:mm''';
																						|en = 'DF=''HH:mm'''; fa = 'DF=''HH:mm''';
																						|it = 'ДФ= ''ЧЧ:мм''';
																						|pl = 'DF=''NN:mm''';
																						|tr = 'DF=''HH:mm'''")));
				Else
					Text = StrReplace(TimePattern, "%TimeFrom%", Format(Parameters.TimeFrom, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																									|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																									|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																									|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																									|pl = 'DF=''dd.MM.yyyy hh:mm''';
																									|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
					Text = StrReplace(Text, "%TimeTo%", Format(Parameters.TimeTo, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																						|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																						|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																						|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																						|pl = 'DF=''dd.MM.yyyy hh:mm''';
																						|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
				EndIf;
			Else
				If BegOfDay(Parameters.TimeFrom) = BegOfDay(Parameters.TimeTo) Then
					Text = StrReplace(TimePattern, "%TimeFrom%", Format(Parameters.TimeFrom, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																									|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																									|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																									|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																									|pl = 'DF=''dd.MM.yyyy hh:mm''';
																									|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
					Text = StrReplace(Text, "%TimeTo%", Format(Parameters.TimeTo, NStr("vi = 'ДФ=''ЧЧ:мм''';
																						|ru = 'ДФ=''HH:mm''';
																						|en = 'DF=''HH:mm'''; fa = 'DF=''HH:mm''';
																						|it = 'ДФ= ''ЧЧ:мм''';
																						|pl = 'DF=''NN:mm''';
																						|tr = 'DF=''HH:mm'''")));
				Else
					Text = StrReplace(TimePattern, "%TimeFrom%", Format(Parameters.TimeFrom, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																									|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																									|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																									|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																									|pl = 'DF=''dd.MM.yyyy hh:mm''';
																									|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
					Text = StrReplace(Text, "%TimeTo%", Format(Parameters.TimeTo, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																						|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																						|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																						|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
																						|pl = 'DF=''dd.MM.yyyy hh:mm''';
																						|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
				EndIf;
			EndIf;
			FlightPoint.Add("," + " " + Text);
		EndIf;
	EndIf;
	
	If FlightPoint.Count() > 0 Then
		Items.SceneryFlightPoint.Title = New FormattedString(FlightPoint);
	Else
		Items.SceneryFlightPoint.Visible = False;
	EndIf;
	
	TitleWeight = NStr("vi = 'Trọng lượng';
						|ru = 'Вес,';
						|en = 'Weight,'; fa = 'Weight,';
						|it = 'Peso,';
						|pl = 'Waga,';
						|tr = 'Ağırlık,'") + " " + UnitOfMeasureForWeight;
	VolumeHeader = NStr("vi = 'Khối lượng,';
						|ru = 'Объем,';
						|en = 'Volume,'; fa = 'Volume,';
						|it = 'Volume,';
						|pl = 'Objętość,';
						|tr = 'Hacim,'") + " " + UnitOfMeasureForVolume;
	Items.ReferencesWeight.Title = TitleWeight;
	Items.GoodsToDeliverWeight.Title = TitleWeight;
	Items.ReferencesVolumeM3.Title = VolumeHeader;
	Items.GoodsToDeliverVolumeM3.Title = VolumeHeader;
	
	References.Load(GetFromTempStorage(Parameters.ReferenceAddress));
	For Each Page1 In References Do
		Page1.Time = GoodsDeliveryClientServer.PresentationOfDeliveryTime(Page1.TimeFrom,Page1.TimeTo);
		Page1.RecipientSenderPresentation = GoodsDeliveryClientServer.PresentationOfSenderSRecipient(
			Page1.RecipientSender, Page1.Carrier, Parameters.DeliveryKind);
	EndDo;
	
	GoodsDeliveryClientServer.DisplayUnderloadOverload(ThisObject, ThisObject);
	
	If Parameters.Property("Status")
	   And Parameters.Status = Enums.StatusesOfTransportationJobs.Closed Then
		
		Items.GoodsToDeliver.Visible = False;
		
	Else
		
		Items.DecorationNoProducts.Visible = False;
		
	EndIf;
	
#Region CalculationOfGoods
	
	ReferencesToOrders = References.Unload(,"ReferenceOrder").UnloadColumn("ReferenceOrder");
	MapTypes = New Map;
	QueryText = "";
	If Parameters.DeliveryKind = Enums.DeliveryKinds.ToWarehouse Then
		For Each Ref In ReferencesToOrders Do // DocumentRef, CatalogRef
			RefType = TypeOf(Ref);
			If RefType = Type("DocumentRef.InstructionForShippingAgent")
				Or MapTypes[RefType] <> Undefined Then
				Continue;
			EndIf;
			MapTypes.Insert(RefType,True);
			ManagerOfDocuments = Common.ObjectManagerByRef(Ref);
			RequestTextGoodsForDeliveryToOurWarehouse = ManagerOfDocuments.QueryTextGoodsToDeliver();
			If QueryText = "" Then
				From_Position = Find(RequestTextGoodsForDeliveryToOurWarehouse, "FROM");
				QueryText = QueryText
					+ Left(RequestTextGoodsForDeliveryToOurWarehouse,From_Position - 1)
					+ " INTO Products_From_Orders
					  |" + Right(RequestTextGoodsForDeliveryToOurWarehouse,StrLen(RequestTextGoodsForDeliveryToOurWarehouse) - From_Position + 1);
			Else
				QueryText = QueryText + "
				|
				|UNION ALL
				|
				|" + RequestTextGoodsForDeliveryToOurWarehouse;
			EndIf;
		EndDo;
		
		If MapTypes.Count() = 0 Then
			
			Items.GoodsToDeliver.Visible = False;
			
			Return; // The orders contain only instructions to forwarders, there are no goods
			
		EndIf;
		
	Else
		QueryText =
		"SELECT
		|	T.DocumentShipments AS Ref,
		|	T.Warehouse,
		|	T.Products,
		|	T.Characteristic,
		|	T.Purpose,
		|	T.Series,
		|	T.ToShipReceipt AS Count
		|INTO Products_From_Orders
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			,
		|			,
		|			,
		|			DocumentShipments IN (&References)) AS T
		|WHERE
		|	T.ToShipReceipt > 0"
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() +
	"SELECT
	|	GoodsToDeliver.Products AS Products,
	|	GoodsToDeliver.Characteristic AS Characteristic,
	|	GoodsToDeliver.Purpose AS Purpose,
	|	GoodsToDeliver.Series AS Series,
	|	GoodsToDeliver.Count AS Count,
	|	GoodsToDeliver.AllGoods AS AllGoods,
	|	GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
	|	GoodsToDeliver.Warehouse AS Warehouse,
	|	GoodsToDeliver.RecipientSender AS RecipientSender
	|INTO TaskItems_
	|FROM
	|	&GoodsToDeliver AS GoodsToDeliver
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder,
	|	References.Warehouse
	|INTO References
	|FROM
	|	&References AS References
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VLGoodsForDelivery.ReferenceOrder,
	|	VLGoodsForDelivery.Warehouse,
	|	VLGoodsForDelivery.RecipientSender,
	|	MIN(VLGoodsForDelivery.AllGoods) AS AllGoods,
	|	VLGoodsForDelivery.Products,
	|	VLGoodsForDelivery.Characteristic,
	|	VLGoodsForDelivery.Purpose,
	|	VLGoodsForDelivery.UnitOfMeasure,
	|	VLGoodsForDelivery.Series,
	|	SUM(VLGoodsForDelivery.Count) AS Count,
	|	SUM(VLGoodsForDelivery.Weight) AS Weight,
	|	SUM(VLGoodsForDelivery.VolumeM3) AS VolumeM3,
	|	MAX(VLGoodsForDelivery.QuantityMaximum) AS QuantityMaximum,
	|	MAX(VLGoodsForDelivery.WeightMaximum) AS WeightMaximum,
	|	MAX(VLGoodsForDelivery.MaximumVolume) AS MaximumVolume,
	|	MAX(VLGoodsForDelivery.UnitVolume) AS UnitVolume,
	|	MAX(VLGoodsForDelivery.UnitWeight) AS UnitWeight
	|FROM
	|	(SELECT
	|		Products_From_Orders.Ref AS ReferenceOrder,
	|		Products_From_Orders.Warehouse AS Warehouse,
	|		TaskItems_.RecipientSender AS RecipientSender,
	|		FALSE AS AllGoods,
	|		Products_From_Orders.Products AS Products,
	|		Products_From_Orders.Characteristic AS Characteristic,
	|		Products_From_Orders.Purpose AS Purpose,
	|		Products_From_Orders.Products.UnitOfMeasure AS UnitOfMeasure,
	|		Products_From_Orders.Series AS Series,
	|		CASE
	|			WHEN TaskItems_.Count > Products_From_Orders.Count
	|				THEN Products_From_Orders.Count
	|			ELSE TaskItems_.Count
	|		END AS Count,
	|		&QueryTextItemWeight * CASE
	|			WHEN TaskItems_.Count > Products_From_Orders.Count
	|				THEN Products_From_Orders.Count
	|			ELSE TaskItems_.Count
	|		END AS Weight,
	|		&QueryTextTheVolumeOfTheItem * CASE
	|			WHEN TaskItems_.Count > Products_From_Orders.Count
	|				THEN Products_From_Orders.Count
	|			ELSE TaskItems_.Count
	|		END AS VolumeM3,
	|		Products_From_Orders.Count AS QuantityMaximum,
	|		Products_From_Orders.Count * &QueryTextItemWeight AS WeightMaximum,
	|		Products_From_Orders.Count * &QueryTextTheVolumeOfTheItem AS MaximumVolume,
	|		&QueryTextTheVolumeOfTheItem AS UnitVolume,
	|		&QueryTextItemWeight AS UnitWeight
	|	FROM
	|		Products_From_Orders AS Products_From_Orders
	|			INNER JOIN TaskItems_ AS TaskItems_
	|			ON Products_From_Orders.Ref = TaskItems_.ReferenceOrder
	|				AND Products_From_Orders.Warehouse = TaskItems_.Warehouse
	|				AND Products_From_Orders.Products = TaskItems_.Products
	|				AND Products_From_Orders.Characteristic = TaskItems_.Characteristic
	|				AND Products_From_Orders.Purpose = TaskItems_.Purpose
	|				AND Products_From_Orders.Series = TaskItems_.Series
	|				AND (NOT TaskItems_.AllGoods)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Products_From_Orders.Ref,
	|		Products_From_Orders.Warehouse,
	|		TaskItems_.RecipientSender,
	|		TRUE,
	|		Products_From_Orders.Products,
	|		Products_From_Orders.Characteristic,
	|		Products_From_Orders.Purpose,
	|		Products_From_Orders.Products.UnitOfMeasure,
	|		Products_From_Orders.Series,
	|		Products_From_Orders.Count,
	|		&QueryTextItemWeight * Products_From_Orders.Count,
	|		&QueryTextTheVolumeOfTheItem * Products_From_Orders.Count,
	|		Products_From_Orders.Count,
	|		Products_From_Orders.Count * &QueryTextItemWeight,
	|		Products_From_Orders.Count * &QueryTextTheVolumeOfTheItem,
	|		&QueryTextTheVolumeOfTheItem,
	|		&QueryTextItemWeight
	|	FROM
	|		Products_From_Orders AS Products_From_Orders
	|			INNER JOIN TaskItems_ AS TaskItems_
	|			ON Products_From_Orders.Ref = TaskItems_.ReferenceOrder
	|				AND Products_From_Orders.Warehouse = TaskItems_.Warehouse
	|				AND (TaskItems_.AllGoods)) AS VLGoodsForDelivery
	|
	|GROUP BY
	|	VLGoodsForDelivery.RecipientSender,
	|	VLGoodsForDelivery.Products,
	|	VLGoodsForDelivery.ReferenceOrder,
	|	VLGoodsForDelivery.Warehouse,
	|	VLGoodsForDelivery.Characteristic,
	|	VLGoodsForDelivery.Series,
	|	VLGoodsForDelivery.UnitOfMeasure,
	|	VLGoodsForDelivery.Purpose
	|
	|ORDER BY
	|	MAX(VLGoodsForDelivery.Weight) DESC,
	|	MAX(VLGoodsForDelivery.VolumeM3) DESC";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"Products_From_Orders.Products.UnitOfMeasure",
		"Products_From_Orders.Products"));
	QueryText = StrReplace(QueryText,
		"&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"Products_From_Orders.Products.UnitOfMeasure",
		"Products_From_Orders.Products"));
	
	GoodsTable = GetFromTempStorage(Parameters.AddressOfGoodsForDelivery);
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("References", ReferencesToOrders);
	Query.SetParameter("GoodsToDeliver", GoodsTable);
	Query.SetParameter("References", References.Unload());
	
	GoodsToDeliver.Load(Query.Execute().Unload());
	
	RecalculateWeightVolumeOfOrdersForGoodsForDelivery();
	
#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CachedValues = New Structure("Count, VolumeM3, Weight");
	OwnerGUID = FormOwner.UUID;
	QuestionWasAsked_ = False;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified
	   And Not QuestionWasAsked_ Then
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Chuyển kết quả cho nhiệm vụ vận chuyển?';
						|ru = 'Перенести результаты в задание на перевозку?';
						|en = 'Transfer results to itinerary?'; fa = 'Transfer results to itinerary?';
						|it = 'Trasferire i risultati nel task di trasporto?';
						|pl = 'Przenieść wyniki do zadania na transport?';
						|tr = 'Sonuçlar taşıma planına aktarılsın mı?'");
		
		CommonClient.ShowFormClosingConfirmation(
			ClosingNotification_,
			Cancel,
			Exit,
			QueryText,
			WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Result, AdditionalParameters) Export
	
	QuestionWasAsked_ = True;
	NotifyChoice(SaveResults());
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SceneryFlightPointURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "ShowVehicle" Then
		Modified = True;
		ShowValue(,Vehicle_);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReferences

&AtClient
Procedure ReferencesOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ReferencesOnActivateRow(Item)
	AttachIdleHandler("InstructionsWhenActivatingWaitHandlerLine", 0.3, True);
EndProcedure

&AtClient
Procedure ReferencesBeforeDeleteRow(Item, Cancel)
	
	CachedValues.Weight = 0;
	CachedValues.VolumeM3 = 0;
	
	For Each IDRw In Items.References.SelectedRows Do // Number
		CurrentRow = References.FindByID(IDRw);
		CachedValues.Weight = CachedValues.Weight + CurrentRow.Weight;
		CachedValues.VolumeM3 = CachedValues.VolumeM3 + CurrentRow.VolumeM3;
	EndDo;
	
	CachedValues.Count = 0;
	
EndProcedure

&AtClient
Procedure ReferencesAfterDeleteRow(Item)
	
	Weight = Weight - CachedValues.Weight;
	VolumeM3 = VolumeM3 - CachedValues.VolumeM3; 
	GoodsDeliveryClientServer.DisplayUnderloadOverload(ThisObject, ThisObject);
	
EndProcedure

&AtClient
Procedure ReferencesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ReferencesReferenceOrder Then
		Modified = True;
		ShowValue(,Items.References.CurrentData.ReferenceOrder);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsToDeliver

&AtClient
Procedure GoodsToDeliverBeforeDeleteRow(Item, Cancel)
	
	CachedValues.Weight = 0;
	CachedValues.VolumeM3 = 0;
	
	SelectedRows = Items.GoodsToDeliver.SelectedRows;
	For Each IDRw In SelectedRows Do
		CurrentRow = GoodsToDeliver.FindByID(IDRw);
		CachedValues.Weight = CachedValues.Weight + CurrentRow.Weight;
		CachedValues.VolumeM3 = CachedValues.VolumeM3 + CurrentRow.VolumeM3;
	EndDo;
	
EndProcedure

&AtClient
Procedure GoodsToDeliverAfterDeleteRow(Item)
	
	CommandLine_ = References.FindByID(Items.References.CurrentRow);
	
	If Items.GoodsToDeliver.CurrentRow = Undefined Then
		References.Delete(CommandLine_);
		ProductWeight   = CommandLine_.Weight;
		VolumeOfGoods = CommandLine_.VolumeM3;
	Else
		ProductWeight   = Min(CachedValues.Weight,   CommandLine_.Weight);
		VolumeOfGoods = Min(CachedValues.VolumeM3, CommandLine_.VolumeM3);
		CommandLine_.Weight   = CommandLine_.Weight   - ProductWeight;
		CommandLine_.VolumeM3 = CommandLine_.VolumeM3 - VolumeOfGoods;
		CommandLine_.DeliveredInFull = False;
	EndIf;
	Weight   = Weight - ProductWeight;
	VolumeM3 = VolumeM3 - VolumeOfGoods; 
	
	GoodsDeliveryClientServer.DisplayUnderloadOverload(ThisObject, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsToDeliverOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.GoodsToDeliver.CurrentData;
	If CurrentRow <> Undefined Then
		FillPropertyValues(CachedValues, Items.GoodsToDeliver.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsToDeliverCountOnChange(Item)
	
	QuantityVolumeWeightWhenChanged("Count");
	
EndProcedure

&AtClient
Procedure GoodsToDeliverWeightOnChange(Item)
	
	QuantityVolumeWeightWhenChanged("Weight");
	
EndProcedure

&AtClient
Procedure GoodsToDeliverVolumeM3OnChange(Item)
	
	QuantityVolumeWeightWhenChanged("VolumeM3");
	
EndProcedure

&AtClient
Procedure GoodsToDeliverBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseAndTransfer(Command)
	
	Result = SaveResults();
	QuestionWasAsked_ = True;
	NotifyChoice(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InstructionsWhenActivatingWaitHandlerLine()
	
	CurrentData = Items.References.CurrentData;
	If CurrentData = Undefined Then
		Items.GoodsToDeliver.RowFilter = New FixedStructure("ReferenceOrder", NULL);
	Else
		Items.GoodsToDeliver.RowFilter = New FixedStructure("ReferenceOrder,Warehouse",
			CurrentData.ReferenceOrder,CurrentData.Warehouse);
	EndIf;
	
EndProcedure

&AtServer
Function SaveResults()
	
	Result = New Structure;
	AllGoods = False;
	
	ReferenceAddress = PutToTempStorage(References.Unload(), OwnerGUID);
	Result.Insert("ReferenceAddress", ReferenceAddress);
	Result.Insert("Weight", References.Total("Weight"));
	Result.Insert("VolumeM3", References.Total("VolumeM3"));
	
	GoodsTable = GoodsToDeliver.Unload();
	GoodsTable.Columns.Add("TransportationJob", New TypeDescription("DocumentRef.TransportationJob"));
	GoodsTable.Sort("ReferenceOrder,Warehouse",New CompareValues());
	CurrentOrder = Undefined;
	CurrentWarehouse = Undefined;
	LinesToDelete = New Array; // Array of ValueTableRow
	For Each Page1 In GoodsTable Do
		
		Page1.TransportationJob = TransportationJob;
		
		If CurrentOrder <> Page1.ReferenceOrder
		 Or CurrentWarehouse <> Page1.Warehouse Then
			
			DeleteRow = False;
			AllGoods = False;
			CurrentOrder = Page1.ReferenceOrder;
			CurrentWarehouse = Page1.Warehouse;
			FoundRows = References.FindRows(New Structure("ReferenceOrder,Warehouse",CurrentOrder,CurrentWarehouse));
			If FoundRows.Count() = 0 Then
				DeleteRow = True;
			Else
				AllGoods = FoundRows[0].DeliveredInFull;
				If AllGoods Then
					Page1.Products = Undefined;
					Page1.Characteristic = Undefined;
					Page1.Purpose = Undefined;
					Page1.Count = 0;
					Page1.Weight = 0;
					Page1.VolumeM3 = 0;
				EndIf;
			EndIf;
			
		ElsIf AllGoods Then
			
			DeleteRow = True;
			
		EndIf;
		
		Page1.AllGoods = AllGoods;
		If DeleteRow Then
			LinesToDelete.Add(Page1);
		EndIf;
		
	EndDo;
	
	For Each Page1 In LinesToDelete Do
		GoodsTable.Delete(Page1);
	EndDo;
	
	AddressOfGoodsForDelivery = PutToTempStorage(GoodsTable, OwnerGUID);
	Result.Insert("AddressOfGoodsForDelivery", AddressOfGoodsForDelivery);
	
	Return Result;
	
EndFunction

&AtClient
Procedure QuantityVolumeWeightWhenChanged(ParameterName)
	
	CurrentRow = Items.GoodsToDeliver.CurrentData;
	
	If CachedValues[ParameterName] = CurrentRow[ParameterName] Then
		Return;
	EndIf;
	
	ElementNames = ItemNamesProductsForDelivery(ParameterName);
	
	CommandLine_ = References.FindByID(Items.References.CurrentRow);
	
	If CachedValues[ParameterName] > CurrentRow[ParameterName] Then
		CommandLine_.DeliveredInFull = False;
		CurrentRow.AllGoods = False;
	EndIf;
	
	If CurrentRow[ParameterName] > CurrentRow[ElementNames.Max] Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Vượt quá giá trị hợp lệ cho trường ''''%1'''', các thay đổi bị loại bỏ.';
				|ru = 'Превышено допустимое значение поля ""%1"", изменения отменены.';
				|en = 'Allowed value of field ""%1"" exceeded, changes are canceled.'; fa = 'Allowed value of field ""%1"" exceeded, changes are canceled.';
				|it = 'Valore ammesso per il campo ""%1"" è superato, modifiche annullate.';
				|pl = 'Przekroczono dopuszczalną wartość pola ""%1"", zmiany zostały anulowane.';
				|tr = '""%1"" alanının izin verilen değeri aşıldı, değişiklikler iptal edildi.'"),
			ParameterName);
		ShowMessageBox(,Text);
		FillPropertyValues(CurrentRow, CachedValues);
		Return;
	EndIf;
	
	If ParameterName <> "Count" Then
		CurrentRow.Count = CurrentRow[ParameterName] / CurrentRow[ElementNames.Units];
	EndIf;
	
	CurrentRow.Weight = CurrentRow.Count * CurrentRow.UnitWeight;
	CurrentRow.VolumeM3 = CurrentRow.Count * CurrentRow.UnitVolume;
	
	WeightLoss   = CachedValues.Weight   - CurrentRow.Weight;
	VolumeReduction = CachedValues.VolumeM3 - CurrentRow.VolumeM3;
	Weight = Weight - WeightLoss;
	VolumeM3 = VolumeM3 - VolumeReduction;
	
	GoodsDeliveryClientServer.DisplayUnderloadOverload(ThisObject, ThisObject);
	
	CommandLine_.Weight   = Max(0,CommandLine_.Weight    - WeightLoss);
	CommandLine_.VolumeM3 = Max(0, CommandLine_.VolumeM3 - VolumeReduction);
	
EndProcedure

&AtClient
Function ItemNamesProductsForDelivery(ParameterName)
	
	ReturnStructure = New Structure("Max, Units", "", "");
	
	If ParameterName = "Count" Then
		ReturnStructure.Units = "UnitQuantity";
		ReturnStructure.Max = "QuantityMaximum";
	ElsIf ParameterName = "Weight" Then
		ReturnStructure.Units = "UnitWeight";
		ReturnStructure.Max = "WeightMaximum";
	ElsIf ParameterName = "VolumeM3" Then
		ReturnStructure.Units = "UnitVolume";
		ReturnStructure.Max = "MaximumVolume";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure RecalculateWeightVolumeOfOrdersForGoodsForDelivery()
	
	For Each ReferenceOrder In References Do
		
		FilterParameters = New Structure("ReferenceOrder, Warehouse",
			ReferenceOrder.ReferenceOrder, ReferenceOrder.Warehouse);
		
		FoundRows = GoodsToDeliver.FindRows(FilterParameters);
		LinesByOrder = GoodsToDeliver.Unload(FoundRows);
		
		ReferenceOrder.Weight = LinesByOrder.Total("Weight");
		ReferenceOrder.VolumeM3 = LinesByOrder.Total("VolumeM3");
		
	EndDo;
	
	Weight = References.Total("Weight");
	VolumeM3 = References.Total("VolumeM3");
	
EndProcedure

#EndRegion