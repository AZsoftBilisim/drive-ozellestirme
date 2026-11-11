// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If Status = Enums.TripStatuses.Prepared Then
		
		NotCheckedAttributeArray.Add("Transport");
		NotCheckedAttributeArray.Add("Driver");
		
	EndIf;
	
	If Status = Enums.TripStatuses.RolledBack_ Then
		
		NotCheckedAttributeArray.Add("DateOfDeparture");
		
	EndIf;
	
	If DeliveryMethod <> Enums.TransportMethods25.ByCarrier Then
		
		NotCheckedAttributeArray.Add("Carrier");
		
	EndIf;
	
	DesignIsFinished = (Status = Enums.TripStatuses.Shipped_5)
		Or (Status = Enums.TripStatuses.Completed)
		Or (Status = Enums.TripStatuses.RolledBack_);
	
	If DesignIsFinished
	   And TypeOf(Vehicle_) <> Type("CatalogRef.Vehicles") Then
		
		ErrorTemplate = NStr("vi = 'Trong trạng thái ""%1"" cần phải chỉ định phương tiện vận tải cụ thể';
							|ru = 'В статусе ""%1"" должно быть указано определенное транспортное средство';
							|en = 'For the ""%1"" status, specify a vehicle'; fa = 'For the ""%1"" status, specify a vehicle';
							|it = 'For the ""%1"" status, specify a vehicle';
							|pl = 'For the ""%1"" status, specify a vehicle';
							|tr = '""%1"" durumunda belirli bir taşıt belirtilmiş olmalıdır'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String(Status));
		Common.MessageToUser(ErrorText, ThisObject, "Transport",, Cancel);
		
	EndIf;
	
	If DateOfDeparture > CurrentSessionDate() Then
		
		If Status = Enums.TripStatuses.Shipped_5 Then
			
			MessageText = NStr("vi = 'Ngày xuất phát của chuyến đi đã gửi không thể lớn hơn ngày hiện tại.';
								|ru = 'Дата выезда в отправленном рейсе не может быть больше текущей.';
								|en = 'The departure date in the started trip cannot be greater than the current one.'; fa = 'The departure date in the started trip cannot be greater than the current one.';
								|it = 'The departure date in the started trip cannot be greater than the current one.';
								|pl = 'The departure date in the started trip cannot be greater than the current one.';
								|tr = 'Gönderilmiş seferdeki çıkış tarihi şu anki tarihten sonra olamaz.'");
			Common.MessageToUser(MessageText, ThisObject, "DateOfDeparture",, Cancel);
			
		ElsIf Status = Enums.TripStatuses.Completed Then
			
			MessageText = NStr("vi = 'Ngày xuất phát của chuyến đi đã hoàn thành không thể lớn hơn ngày hiện tại.';
								|ru = 'Дата выезда в завершенном рейсе не может быть больше текущей.';
								|en = 'The departure date in the completed trip cannot be greater than the current one.'; fa = 'The departure date in the completed trip cannot be greater than the current one.';
								|it = 'The departure date in the completed trip cannot be greater than the current one.';
								|pl = 'The departure date in the completed trip cannot be greater than the current one.';
								|tr = 'Tamamlanmış seferdeki çıkış tarihi şu anki tarihten sonra olamaz.'");
			Common.MessageToUser(MessageText, ThisObject, "DateOfDeparture",, Cancel);
			
		EndIf;
		
	EndIf;
	
	CheckingRouteFilling(NotCheckedAttributeArray, Cancel);
	CheckingContentFilling(CheckedAttributes, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If DeliveryMethod = Enums.TransportMethods25.OwnDelivery Then
		
		Carrier = Catalogs.Partners.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		
	EndIf;
	
	DeleteIrrelevantContentLines();
	AddStartLineOfRoute();
	RoundUpCheckOutAndDeliveryTimes();
	
	Weight = 0;
	VolumeM3 = 0;
	For Each TableRow In Content Do
		
		If Not TableRow.SpecialTransportationConditions Then
			TableRow.SpecialTransportationConditionsDescription = "";
		EndIf;
		
		If TableRow.Canceled Then
			Continue;
		EndIf;
		
		Weight = Weight + TableRow.Weight;
		VolumeM3 = VolumeM3 + TableRow.VolumeM3;
		
	EndDo;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IsNew = AdditionalProperties.DocumentsPosting.DocumentProperties.IsNew; // Boolean
	FlightStatusClosesOrders =
		(Status = Enums.TripStatuses.Shipped_5
			Or Status = Enums.TripStatuses.Completed);
	
	If Not Cancel
		And FlightStatusClosesOrders
		And Not IsNew Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	ExpenseOrder.Ref AS Ref
		|FROM
		|	Document.GoodsIssueNote AS ExpenseOrder
		|WHERE
		|	ExpenseOrder.TransportationJob = &Trip
		|	AND ExpenseOrder.Status = VALUE(Enum.GoodsIssueNoteStatuses.ToShip)
		|	AND ExpenseOrder.Posted
		|	AND ExpenseOrder.ShipmentUnderTransportationJob";
		Query.SetParameter("Trip", Ref);
		
		If Not Query.Execute().IsEmpty() Then
			
			WarehousesServer.StartingBackgroundTransferOfStatusOfSpendingOrderToShipped(Ref);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Internal

Procedure AddStartLineOfRoute() Export
	
	If Not ValueIsFilled(DepartureWarehouse) Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("Point", DepartureWarehouse);
	Filter.Insert("DeliveryPoint", DeparturePoint_);
	Filter.Insert("Operation", Enums.TripOperations.Loading);
	Rows = Route.FindRows(Filter);
	
	If Rows.Count() > 0 Then
		
		RouteStartLine = Rows[0];
		RowIndex = Route.IndexOf(RouteStartLine);
		If RowIndex > 0 Then
			Route.Move(RouteStartLine, -1 * RowIndex);
		EndIf;
		
	Else
		
		RouteStartLine = Route.Insert(0);
		RouteStartLine.Point = DepartureWarehouse;
		RouteStartLine.DeliveryPoint = DeparturePoint_;
		RouteStartLine.Operation = Enums.TripOperations.Loading;
		RouteStartLine.ConnectionKey = New UUID();
		RouteStartLine.DeliveryZone = DepartureArea;
		
	EndIf;
	
EndProcedure

Procedure DeleteIrrelevantContentLines() Export
	
	ColumnName = "ConnectionKey";
	
	TempTable = Content.Unload(, ColumnName);
	TempTable.GroupBy(ColumnName);
	CommunicationKeysContent = TempTable.UnloadColumn(ColumnName);
	
	TempTable = Route.Unload(, ColumnName);
	TempTable.GroupBy(ColumnName);
	RouteCommunicationKeys = TempTable.UnloadColumn(ColumnName);
	
	IrrelevantCommunicationKeys = CommonClientServer.ArraysDifference(CommunicationKeysContent, RouteCommunicationKeys); // Array of UUID
	RowFilter = New Structure("ConnectionKey", New UUID());
	
	For Each ConnectionKey In IrrelevantCommunicationKeys Do
		
		RowFilter.ConnectionKey = ConnectionKey;
		StringsByKey = Content.FindRows(RowFilter);
		For Each TableRow In StringsByKey Do
			Content.Delete(TableRow);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Status = Enums.TripStatuses.Prepared;
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	SenderSPointDataIsFilledIn = False;
	
	If Not ValueIsFilled(DeparturePoint_) Then
		
		SenderSPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(DepartureWarehouse);
		DeparturePoint_ = SenderSPointData.DeliveryPoint;
		DepartureArea = SenderSPointData.DeliveryZone;
		SenderSPointDataIsFilledIn = True;
		
	EndIf;
	
	If Not ValueIsFilled(DepartureArea)
	   And ValueIsFilled(DeparturePoint_)
	   And Not SenderSPointDataIsFilledIn Then
		
		DetailsOfPointOfDeparture = Common.ObjectAttributesValues(DeparturePoint_, "DeliveryZone");
		DepartureArea = DetailsOfPointOfDeparture.DeliveryZone;
		
	EndIf;
	
	AddStartLineOfRoute();
	
EndProcedure

Procedure CheckingRouteFilling(NotCheckedAttributeArray, Cancel)
	
	TSName = Metadata().TabularSections.Route.Name;
	TSSynonym = Metadata().TabularSections.Route.Synonym;
	
	CheckParameters = TableValidationParameters();
	CheckParameters.StringInitialIndex = 1;
	CheckParameters.TabularSectionName = TSName;
	CheckParameters.ErrorTemplate = NStr("vi = 'Chưa điền cột ""[ColumnSynonym]"" tại dòng [LineNumber] trong danh sách ""[TableSectionSynonym]"".';
										|ru = 'Не заполнена колонка ""[ColumnSynonym]"" в строке [LineNumber] списка ""[SynonymForTablePart]""';
										|en = 'The ""[ColumnSynonym]"" column in line [LineNumber] of the ""[SynonymForTablePart]"" list is not filled in'; fa = 'The ""[ColumnSynonym]"" column in line [LineNumber] of the ""[SynonymForTablePart]"" list is not filled in';
										|it = 'The ""[ColumnSynonym]"" column in line [LineNumber] of the ""[SynonymForTablePart]"" list is not filled in';
										|pl = 'The ""[ColumnSynonym]"" column in line [LineNumber] of the ""[SynonymForTablePart]"" list is not filled in';
										|tr = '""[SynonymForTablePart]"" listesindeki [LineNumber]  satırında ""[ColumnSynonym]"" sütunu doldurulmadı'");
	CheckFillingOfColumnsInTablePart(Route, CheckParameters, NotCheckedAttributeArray, Cancel);
	
	KeyColumns = New Array; // Array of String
	KeyColumns.Add("Point");
	KeyColumns.Add("DeliveryPoint");
	KeyColumns.Add("Operation");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, TSName, KeyColumns, Cancel, TSSynonym);
	
	If DeliveryMethod = Enums.TransportMethods25.ByCarrier
		And Not Carrier.IsEmpty() Then
		
		MessageTemplate = NStr("vi = 'Thông tin của người nhận và người vận chuyển trùng nhau (%1), không thể lập vận chuyển.';
								|ru = 'Совпадают данные получателя и перевозчика (%1), оформление доставки невозможно.';
								|en = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.'; fa = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
								|it = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
								|pl = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
								|tr = 'Alıcı ve taşıyıcı verileri (%1) eşleşiyor, teslimat oluşturma mümkün değil.'");
		PresentationOfCarrier = String(Carrier);
		
		For Each RouteString In Route Do
			
			If RouteString.Canceled Then
				Continue;
			EndIf;
			
			If Carrier = RouteString.Point Then
				
				LineNumber = Format(RouteString.LineNumber, "NG=");
				PathToField = CommonClientServer.PathToTabularSection(
					"Route", RouteString.LineNumber, "Point");
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					MessageTemplate,
					PresentationOfCarrier,
					LineNumber);
				
				Common.MessageToUser(ErrorText, ThisObject, PathToField,, Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function TableValidationParameters()
	
	Result = New Structure;
	
	Result.Insert("TabularSectionName", "");
	Result.Insert("ErrorTemplate", "");
	Result.Insert("NameOfTabularPartOfPath", "");
	Result.Insert("NameOfPathColumn", "");
	Result.Insert("LineNumberOfPath", 0);
	Result.Insert("StringInitialIndex", 0);
	Result.Insert("SkipCanceledLines", False);
	
	Return Result;
	
EndFunction

Procedure CheckFillingOfColumnsInTablePart(Table, CheckParameters, NotCheckedAttributeArray, Cancel)
	
	TabularSectionName = CheckParameters.TabularSectionName;
	SynonymForTablePart = Metadata().TabularSections[TabularSectionName].Synonym;
	If ValueIsFilled(CheckParameters.NameOfTabularPartOfPath) Then
		NameOfTabularPartOfPath = CheckParameters.NameOfTabularPartOfPath;
	Else
		NameOfTabularPartOfPath = TabularSectionName;
	EndIf;
	
	ColumnsToCheck = New Map;
	For Each Attribute In Metadata().TabularSections[TabularSectionName].Attributes Do
		
		If Attribute.FillChecking = FillChecking.ShowError Then
			
			ColumnsToCheck.Insert(Attribute.Name, Attribute.Synonym);
			NotCheckedAttributeArray.Add(TabularSectionName + "." + Attribute.Name);
			
		EndIf;
		
	EndDo;
	
	MessageParameters = New Structure;
	MessageParameters.Insert("ColumnSynonym", "");
	MessageParameters.Insert("LineNumber", "");
	MessageParameters.Insert("SynonymForTablePart", SynonymForTablePart);
	
	For RowIndex = CheckParameters.StringInitialIndex To Table.Count() - 1 Do
		
		TableRow = Table.Get(RowIndex);
		If CheckParameters.SkipCanceledLines
			And TableRow.Canceled Then
			
			Continue;
			
		EndIf;
		MessageParameters.LineNumber = String(TableRow.LineNumber);
		
		If ValueIsFilled(CheckParameters.LineNumberOfPath) Then
			LineNumberOfPath = CheckParameters.LineNumberOfPath;
		Else
			LineNumberOfPath = TableRow.LineNumber;
		EndIf;
		
		For Each KeyAndValue In ColumnsToCheck Do
			
			ColumnName = KeyAndValue.Key; // String
			MessageParameters.ColumnSynonym = KeyAndValue.Value; // String
			
			If ValueIsFilled(CheckParameters.NameOfPathColumn) Then
				NameOfPathColumn = CheckParameters.NameOfPathColumn;
			Else
				NameOfPathColumn = ColumnName;
			EndIf;
			
			If Not ValueIsFilled(TableRow[ColumnName]) Then
				
				ErrorText = StringFunctionsClientServer.InsertParametersIntoString(
					CheckParameters.ErrorTemplate, MessageParameters);
				Path = CommonClientServer.PathToTabularSection(
					NameOfTabularPartOfPath, LineNumberOfPath, NameOfPathColumn);
				
				Common.MessageToUser(
					ErrorText, ThisObject, Path,, Cancel);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CheckingContentFilling(CheckedAttributes, NotCheckedAttributeArray, Cancel)
	
	NameOfTSRoute = Metadata().TabularSections.Route.Name;
	TSNameContent = Metadata().TabularSections.Content.Name;
	ColumnNameComposition = "Content";
	
	NotCheckedAttributeArray.Add(TSNameContent);
	
	TemplateErrorFillingInCancellationReasons = NStr("vi = 'Chưa điền nnguyên nhân hủy bỏ tại dòng %1 của nội dung theo dòng lộ trình %2';
													|ru = 'Не заполнена причина отмены в строке %1 содержимого по строке маршрута %2';
													|en = 'The cancellation reason is missing in line %1 of the content for route line %2'; fa = 'The cancellation reason is missing in line %1 of the content for route line %2';
													|it = 'The cancellation reason is missing in line %1 of the content for route line %2';
													|pl = 'The cancellation reason is missing in line %1 of the content for route line %2';
													|tr = '%2 rota satırına ait içeriğin %1 satırında iptal sebebi doldurulmamış'");
	ErrorTemplateNoContent = NStr("vi = 'Chưa điền nội dung tại dòng %1 của lộ trình';
									|ru = 'Не заполнено содержимое в строке %1 маршрута';
									|en = 'The content is missing in route line %1'; fa = 'The content is missing in route line %1';
									|it = 'The content is missing in route line %1';
									|pl = 'The content is missing in route line %1';
									|tr = '%1 rota satırında içerik doldurulmamış'");
	TemplateQuantityError = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của nội dung theo dòng lộ trình %3';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 содержимого по строке маршрута %3';
								|en = 'The ""%1"" column is not filled in line %2 of the content for route line %3'; fa = 'The ""%1"" column is not filled in line %2 of the content for route line %3';
								|it = 'The ""%1"" column is not filled in line %2 of the content for route line %3';
								|pl = 'The ""%1"" column is not filled in line %2 of the content for route line %3';
								|tr = '%3 rota satırına ait içeriğin %2 satırında ""%1"" sütunu doldurulmamış'");
	TemplateRecalculationError = NStr("vi = 'Tìm thấy số lượng bằng 0 khi kiểm đếm theo đơn vị cất giữ tại dòng %1 của nội dung theo dòng lộ trình %2';
										|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %1 содержимого по строке маршрута %2';
										|en = 'Zero quantity is detected when converted to storage unit in line %1 of the content for route line %2'; fa = 'Zero quantity is detected when converted to storage unit in line %1 of the content for route line %2';
										|it = 'Zero quantity is detected when converted to storage unit in line %1 of the content for route line %2';
										|pl = 'Zero quantity is detected when converted to storage unit in line %1 of the content for route line %2';
										|tr = '%2 rota satırına ait içeriğin %1 satırındaki miktar stok ölçü birimine dönüştürülürken sıfır miktar bulundu'");
	PresentationOfPropsNumberOfPackages = Metadata().TabularSections.Content.Attributes.NumberOfPackages.Synonym;
	
	RowFilter = New Structure();
	RowFilter.Insert("ConnectionKey", CommonClientServer.BlankUUID());
	
	RoundingCheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	RoundingCheckParameters.TSName = Metadata().TabularSections.Content.Name;
	RoundingCheckParameters.ConditionForSelectingRowsForRounding = "Content.ConnectionKey = &ConnectionKey";
	
	For RouteLineIndex = 1 To Route.Count() - 1 Do
		
		RouteString = Route.Get(RouteLineIndex);
		RouteLineNumberInText = Format(RouteString.LineNumber, "NG=;");
		
		RowFilter.ConnectionKey = RouteString.ConnectionKey;
		ContentByRouteLine = Content.Unload(RowFilter);
		If ContentByRouteLine.Count() = 0 Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplateNoContent, RouteLineNumberInText);
			Path = CommonClientServer.PathToTabularSection(NameOfTSRoute, RouteString.LineNumber, ColumnNameComposition);
			Common.MessageToUser(ErrorText, ThisObject, Path,, Cancel);
			
			Continue;
			
		EndIf;
		
		RowsCount = ContentByRouteLine.Count() - 1;
		For IndexOfContentLine = 0 To RowsCount Do
			ContentByRouteLine[IndexOfContentLine].LineNumber = IndexOfContentLine + 1;
		EndDo;
		
		CheckParameters = TableValidationParameters();
		CheckParameters.TabularSectionName = TSNameContent;
		CheckParameters.ErrorTemplate = NStr("vi = 'Chưa điền cột ""[ColumnSynonym]"" tại dòng [LineNumber] của nội dung theo dòng lộ trình %1';
											|ru = 'Не заполнена колонка ""[ColumnSynonym]"" в строке [LineNumber] содержимого по строке маршрута %1';
											|en = 'The ""[ColumnSynonym]"" column is not filled in line [LineNumber] of the content for route line %1'; fa = 'The ""[ColumnSynonym]"" column is not filled in line [LineNumber] of the content for route line %1';
											|it = 'The ""[ColumnSynonym]"" column is not filled in line [LineNumber] of the content for route line %1';
											|pl = 'The ""[ColumnSynonym]"" column is not filled in line [LineNumber] of the content for route line %1';
											|tr = '%1 rota satırına ait içeriğin [LineNumber] satırında ""[ColumnSynonym]"" sütunu doldurulmamış'");
		CheckParameters.ErrorTemplate = StringFunctionsClientServer.SubstituteParametersToString(
			CheckParameters.ErrorTemplate,
			RouteLineNumberInText);
		CheckParameters.NameOfTabularPartOfPath = NameOfTSRoute;
		CheckParameters.NameOfPathColumn = ColumnNameComposition;
		CheckParameters.LineNumberOfPath = RouteString.LineNumber;
		CheckParameters.SkipCanceledLines = True;
		
		CheckFillingOfColumnsInTablePart(
			ContentByRouteLine,
			CheckParameters,
			NotCheckedAttributeArray,
			Cancel);
		
		For Each RowWithContent In ContentByRouteLine Do
			
			LineNumberOfContentInText = String(RowWithContent.LineNumber);
			Path = CommonClientServer.PathToTabularSection(NameOfTSRoute, RouteString.LineNumber, ColumnNameComposition);
			
			If RowWithContent.Canceled Then
				
				If RowWithContent.CancellationReason.IsEmpty() Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						TemplateErrorFillingInCancellationReasons,
						LineNumberOfContentInText,
						RouteLineNumberInText);
					Common.MessageToUser(ErrorText, ThisObject, Path,, Cancel);
					
				EndIf;
				
				Continue;
				
			EndIf;
			
			If RowWithContent.NumberOfPackages = 0 Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateQuantityError,
					PresentationOfPropsNumberOfPackages,
					LineNumberOfContentInText,
					RouteLineNumberInText);
				Common.MessageToUser(ErrorText, ThisObject, Path,, Cancel);
				
			EndIf;
			
			If RowWithContent.Count = 0
				And RowWithContent.NumberOfPackages <> 0 Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateRecalculationError, LineNumberOfContentInText, RouteLineNumberInText);
				Common.MessageToUser(ErrorText, ThisObject, Path,, Cancel);
				
			EndIf;
			
		EndDo;
		
		RoundingCheckParameters.PresentationOfTS = NStr("vi = 'dòng %1 của lộ trình';
														|ru = 'строка %1 маршрута';
														|en = '%1 route line'; fa = '%1 route line';
														|it = '%1 route line';
														|pl = '%1 route line';
														|tr = '%1 rota satırı'");
		RoundingCheckParameters.PresentationOfTS = StringFunctionsClientServer.SubstituteParametersToString(
			RoundingCheckParameters.PresentationOfTS,
			RouteLineNumberInText);
		
		RoundingCheckParameters.QueryOptions.Insert("ConnectionKey", RouteString.ConnectionKey);
		RoundingCheckParameters.DataPath = CommonClientServer.PathToTabularSection(
			NameOfTSRoute, RouteString.LineNumber, ColumnNameComposition);
		
		ProductsServer.CheckQuantityRounding(ThisObject, Cancel, RoundingCheckParameters);
		
	EndDo;
	
EndProcedure

Procedure RoundUpCheckOutAndDeliveryTimes()
	
	DepartureTime = BegOfMinute(DepartureTime);
	
	BeginningOfDay = '00010101000001';
	
	For Each RouteString In Route Do
		
		If RouteString.DeliveryTimeFrom <> BeginningOfDay Then
			
			RouteString.DeliveryTimeFrom = BegOfMinute(RouteString.DeliveryTimeFrom);
			
		EndIf;
		
		If RouteString.DeliveryTimeTo <> BeginningOfDay Then
			
			RouteString.DeliveryTimeTo = BegOfMinute(RouteString.DeliveryTimeTo);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf