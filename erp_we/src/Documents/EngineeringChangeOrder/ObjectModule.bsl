#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	If GetFunctionalOption("UseProductionManagement2_2") Then
		
		For Each ScopeString In AreasOfAction Do
		
			If ValueIsFilled(ScopeString.SalesOrder) Then
				ScopeString.SalesOrder = Documents.SalesOrder.EmptyRef();
			EndIf;
			If ValueIsFilled(ScopeString.ProductionOrder) 
				And TypeOf(ScopeString.ProductionOrder) <> Type("DocumentRef.ProductionOrder2_2") Then
				ScopeString.ProductionOrder = Undefined;
			EndIf;
		
		EndDo;
		
	EndIf;
	
	For Each TableRow In UsedMaterials Do
		TableRow.RowID = New UUID;
	EndDo;
	
	For Each TableRow In Substitutes Do
		TableRow.RowID = New UUID;
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("Substitute") Then
			NewRow = Substitutes.Add();
			NewRow.Products = FillingData.Substitute;
			NewRow.RowID = New UUID;
			
			ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
			
		EndIf;
		
		If FillingData.Property("UsedMaterials") Then
			
			For Each StringMaterial In FillingData.UsedMaterials Do
				
				TableRow = UsedMaterials.Add();
				FillPropertyValues(TableRow, StringMaterial);
				
				If Not ValueIsFilled(TableRow.RowID) Then
					TableRow.RowID = New UUID;
				EndIf;
				
			EndDo;
			
			ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
			
		EndIf;
		
		If FillingData.Property("BillOfMaterials") Then
			ScopeString = AreasOfAction.Add();
			ScopeString.BillOfMaterials = FillingData.BillOfMaterials;
			
			ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
			
		EndIf;
		
		If FillingData.Property("ProductionOrder") Then
			
			ScopeString = AreasOfAction.Add();
			ScopeString.ProductionOrder = FillingData.ProductionOrder;
			
			ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
			
		EndIf;
		
		If FillingData.Property("InterchangeableSubstitutes")
		   And FillingData.Property("DocumentPermissions")
		   And FillingData.InterchangeableSubstitutes Then
		   
			Attributes = "ReplacementOption, UsedMaterials, Substitutes, AreasOfAction";
			AttributesStructure1 = Common.ObjectAttributesValues(FillingData.DocumentPermissions, Attributes);
			ReplacementOption = AttributesStructure1.ReplacementOption;
			UsedMaterials.Load(AttributesStructure1.Substitutes.Unload());
			Substitutes.Load(AttributesStructure1.UsedMaterials.Unload());
			AreasOfAction.Load(AttributesStructure1.AreasOfAction.Unload());
			
		EndIf;
		
	ElsIf FillInDataType = Type("CatalogRef.BillsOfMaterials") Then
		
		ScopeString = AreasOfAction.Add();
		ScopeString.BillOfMaterials = FillingData;
		
		ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
		
	ElsIf FillInDataType = Type("DocumentRef.ProductionOrder2_2")
			Then
			
		ScopeString = AreasOfAction.Add();
		ScopeString.ProductionOrder = FillingData;
		
		ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
		
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then
		
		UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
		
		If Not UseOrderSupplyWithAssignment Then
			ExceptionText = NStr("vi = 'Quyền thay thế có thể được nhập bằng cách sử dụng đảm bảo đơn hàng đặt riêng.';
								|ru = 'Ввод разрешений на замену возможен при использовании обособленного обеспечения заказов.';
								|en = 'You can enter the substitution permissions when using assigned order fulfillment.'; fa = 'You can enter the substitution permissions when using assigned order fulfillment.';
								|it = 'L''immissione dei permessi di sostituzione è possibile utilizzando approvvigionamento degli ordini separato.';
								|pl = 'Wprowadzanie pozwoleń na wymianę jest możliwe przy użyciu oddzielnego zabezpieczenia zamówienia.';
								|tr = 'Ayrı sipariş temini kullanıldığında değiştirme izinlerinin girişi mümkündür.'");
			Raise ExceptionText;
		EndIf;
		
		If Not ThereAreProductsUnderOrder(FillingData) Then
			ExceptionText = NStr("vi = 'Có thể nhập quyền được phép thay thế khi có hàng hóa với thao tác ""Cần đảm bảo"" hoặc ""Dự phòng theo phương thức tiếp nhận"" và có đặt dấu hộp kiểm ""Đặt riêng"".';
								|ru = 'Ввод разрешений на замену возможен при наличии товаров с действием ""К обеспечению"" или ""Резервировать по мере поступления"" и с установленным флагом ""Обособленно"".';
								|en = 'You can enter the substitution permissions if there are goods with the ""To supply"" or ""Reserve upon receipt"" action and with the ""Assigned"" check box selected.'; fa = 'You can enter the substitution permissions if there are goods with the ""To supply"" or ""Reserve upon receipt"" action and with the ""Assigned"" check box selected.';
								|it = 'È possibile inserire permessi di sostituzione se sono disponibili merci con azione ""Da approvvigionare"" o ""Prenotare in base agli arrivi"" e con il flag ""Separatamente"" impostato.';
								|pl = 'Wprowadzenie zezwoleń do zmiany jest możliwe przy dostępnych towarach z działaniem ""Do zaopatrzenia"" lub ""Zarezerwuj w miarę otrzymania"" i z zaznaczonym polem wyboru ""Oddzielnie"".';
								|tr = 'Değiştirme izinlerinin girişi, ""Sağlanacak"" veya ""Girişte Rezerve Et"" eylemine sahip ürünler varsa ve ""Atanmış"" işareti yapılandırılmış ise mümkündür.'");
			Raise ExceptionText;
		EndIf;
		
		ScopeString = AreasOfAction.Add();
		ScopeString.SalesOrder = FillingData;
		
		ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
		
	EndIf;
	
	If AreasOfAction.Count() = 0 Then
		AreasOfAction.Add();
	EndIf;
	
	InitializeDocument(FillingData);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);

	If Not ValueIsFilled(ReplacementOption) Then
		ReplacementOption = Enums.SubstituteReplacementOption.SetToSet;
	EndIf;
	
	If Not ValueIsFilled(ReplacementPriority) Then
		ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials;
	EndIf;
	
	If UsedMaterials.Count() > 1
	 Or Substitutes.Count() > 1 Then
	 	
	 	InterchangeableSubstitutes = False;
		If ReplacementOption = Enums.SubstituteReplacementOption.SetToSet Then
			UseItForAutocorrectInOrders = False;
		EndIf;
	 	
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// The expiration date of the agreement must not be less than the start date of the agreement.
	If ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then
		
		If ValidityStartDate > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hạn của giấy phép không được ít hơn ngày bắt đầu';
							|ru = 'Дата окончания действия разрешения должна быть не меньше даты начала';
							|en = 'Permission validity expiration date must be greater than the start date'; fa = 'Permission validity expiration date must be greater than the start date';
							|it = 'La data di fine dell''azione non deve essere precedente alla data di inizio';
							|pl = 'Data wygaśnięcia zezwolenia nie może być mniejsza niż data rozpoczęcia';
							|tr = 'İzin geçerliliğinin bitiş tarihi, başlangıç tarihinden önce olmamalıdır'");
			Common.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	If Status <> Enums.StatusesOfEngineeringChangeOrders.Terminated Then
		NotCheckedAttributeArray.Add("ValidityEndDate");
	EndIf;
	
	If ReplacementOption = Enums.SubstituteReplacementOption.SubstituteList Then

		NotCheckedAttributeArray.Add("Substitutes");
		NotCheckedAttributeArray.Add("Substitutes.Products");
		NotCheckedAttributeArray.Add("Substitutes.Characteristic");
		NotCheckedAttributeArray.Add("UsedMaterials.NumberOfPackages");
		
		CheckSetDuplicates("UsedMaterials", NStr("vi = 'Đã tìm thấy sự trùng lặp các dòng trong tập hợp nguyên vật liệu.';
												|ru = 'Обнаружено дублирование строк в наборе материалов.';
												|en = 'Duplicate lines are found in the material set.'; fa = 'Duplicate lines are found in the material set.';
												|it = 'Обнаружено дублирование строк в наборе материалов.';
												|pl = 'Duplicate lines are found in the material set.';
												|tr = 'Malzeme kümesinde satırların çoğaltılması tespit edildi.'"), Cancel);
		
		If UsedMaterials.Count() < 2 Then
		
			ErrorText = NStr("vi = 'Trong danh sách vật tư tương tự, cần chỉ ra nhiều hơn một dòng';
							|ru = 'В списке аналогов должно быть указано более одной строки';
							|en = 'The list of substitutes must have more than one line'; fa = 'The list of substitutes must have more than one line';
							|it = 'В списке аналогов должно быть указано более одной строки';
							|pl = 'The list of substitutes must have more than one line';
							|tr = 'İkamelerin listesi birden fazla satır içermelidir'");
			Common.MessageToUser(
				ErrorText,
				ThisObject, 
				"UsedMaterials",
				,
				Cancel);
		
		EndIf;
		
	ElsIf ReplacementOption = Enums.SubstituteReplacementOption.SetToSet Then 
		
		CheckSetDuplicates("UsedMaterials", NStr("vi = 'Đã tìm thấy sự trùng lặp các dòng trong tập hợp nguyên vật liệu.';
												|ru = 'Обнаружено дублирование строк в наборе материалов.';
												|en = 'Duplicate lines are found in the material set.'; fa = 'Duplicate lines are found in the material set.';
												|it = 'Обнаружено дублирование строк в наборе материалов.';
												|pl = 'Duplicate lines are found in the material set.';
												|tr = 'Malzeme kümesinde satırların çoğaltılması tespit edildi.'"), Cancel);
		CheckSetDuplicates("Substitutes", NStr("vi = 'Các hàng trùng lặp được tìm thấy trong một tập hợp các chất tương tự.';
												|ru = 'Обнаружено дублирование строк в наборе аналогов.';
												|en = 'Duplicate lines are found in the list of substitutes.'; fa = 'Duplicate lines are found in the list of substitutes.';
												|it = 'Nella serie di analoghi si è verificata la duplicazione delle righe.';
												|pl = 'Znaleziono zduplikowane wiersze w zestawie analogów.';
												|tr = 'İkameler kümesinde satırların çoğaltılması tespit edildi.'"), Cancel);
		
	EndIf;
	
	If ReplacementOption <> Enums.SubstituteReplacementOption.SubstituteList Then
		CheckIdentityOfSets(Cancel);
		CheckDuplicatesOfScope(Cancel);
		CheckFillingOfQuantityInLowerPart("UsedMaterials", Cancel);
	EndIf;
		
	NotCheckedAttributeArray.Add("UsedMaterials.NumberOfPackages");
	NotCheckedAttributeArray.Add("Substitutes.NumberOfPackages");
		
	CheckFillingOfQuantityInLowerPart("Substitutes", Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "UsedMaterials";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	CheckParameters.TSName = "Substitutes";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	BlankUUID = New UUID("00000000-0000-0000-0000-000000000000");
	FoundRows = UsedMaterials.FindRows(New Structure("RowID", BlankUUID));
	For Each TableRow In FoundRows Do
		TableRow.RowID = New UUID;
	EndDo;
	
	FoundRows = Substitutes.FindRows(New Structure("RowID", BlankUUID));
	For Each TableRow In FoundRows Do
		TableRow.RowID = New UUID;
	EndDo;
	
	If ReplacementOption = Enums.SubstituteReplacementOption.SubstituteList Then
		
		EmptyPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		Substitutes.Clear();
		
		For Each TableRow In UsedMaterials Do
			
			TableRow.NumberOfPackages = 1;
			TableRow.Package = EmptyPackaging;
			
		EndDo;
		
	EndIf;
	
	If UsedMaterials.Count() > 1
	 Or Substitutes.Count() > 1 Then
	 	
	 	InterchangeableSubstitutes = False;
		If ReplacementOption = Enums.SubstituteReplacementOption.SetToSet Then
			UseItForAutocorrectInOrders = False;
		EndIf;
	 	
	EndIf;
	
	If ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute Then
	
		CheckIntersectionOfScope(Cancel, WriteMode);
		InterchangeableSubstitutes = False;
	
	EndIf;
		
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
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
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible			= Users.AuthorizedUser();
	ValidityStartDate		= BegOfDay(CurrentSessionDate());
	Status					= Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		
EndProcedure

Function ThereAreProductsUnderOrder(Var_Ref)
	
	FilterStructure1 = New Structure("SupplyOption, WithAssignment", 
									   Enums.SupplyOptions.ReserveAsReceived, True);
	
	FoundRows = Var_Ref.Goods.FindRows(FilterStructure1);
	
	If FoundRows.Count() = 0 Then
		FilterStructure1 = New Structure("SupplyOption, WithAssignment", 
										   Enums.SupplyOptions.ToSupply, True);
		
		FoundRows = Var_Ref.Goods.FindRows(FilterStructure1);
	EndIf;

	If FoundRows.Count() = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Procedure CheckSetDuplicates(SetName, Message, Cancel)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.LineNumber
	|INTO TTSet
	|FROM
	|	&Set AS Set
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Set.Products,
	|	Set.Characteristic,
	|	MAX(Set.LineNumber) AS LineNumber
	|FROM
	|	TTSet AS Set
	|
	|GROUP BY
	|	Set.Products,
	|	Set.Characteristic
	|
	|HAVING
	|	COUNT(DISTINCT Set.LineNumber) > 1";
	
	Query.SetParameter("Set", ThisObject[SetName]);
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		Common.MessageToUser(
			Message,
			ThisObject,
			SetName + "[" + (Selection.LineNumber - 1) + "].Products",
			"Object",
			Cancel);
		
	EndDo;
	
EndProcedure

Procedure CheckFillingOfQuantityInLowerPart(TSName, Cancel)
	
	ObjectTable = ThisObject[TSName]; // DocumentTabularSection.EngineeringChangeOrder.UsedMaterials, DocumentTabularSection.EngineeringChangeOrder.Substitutes - 
	
	For Each String In ObjectTable Do
		
		If String.NumberOfPackages = 0 Then
			
			MessageText = CommonClientServer.FillingErrorText(
				"Column", "FillType", NStr("vi = 'Số lượng';
											|ru = 'Количество';
											|en = 'Quantity'; fa = 'مقدار';
											|it = 'Quantità';
											|pl = 'Ilość';
											|tr = 'Miktar'"), String.LineNumber, TSName);
				
			Common.MessageToUser(MessageText,
				ThisObject,
				CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "NumberOfPackages"),,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckIdentityOfSets(Cancel)
	
	If Not Cancel
	   And UsedMaterials.Count() = Substitutes.Count() Then
	
		Query = New Query;
		Query.Text = 
		"SELECT
		|	UsedMaterials.Products AS Products,
		|	UsedMaterials.Characteristic AS Characteristic,
		|	UsedMaterials.Package AS Package,
		|	UsedMaterials.NumberOfPackages AS NumberOfPackages
		|INTO TT_UsedMaterials
		|FROM
		|	&UsedMaterials AS UsedMaterials
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Substitutes.Products AS Products,
		|	Substitutes.Characteristic AS Characteristic,
		|	Substitutes.Package AS Package,
		|	Substitutes.NumberOfPackages AS NumberOfPackages
		|INTO TT_Substitutes
		|FROM
		|	&Substitutes AS Substitutes
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TRUE AS Flag,
		|	&QueryTextMaterialPackingRatio AS Field1
		|FROM
		|	TT_UsedMaterials AS TT_UsedMaterials
		|WHERE
		|	NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					TT_Substitutes AS TT_Substitutes
		|				WHERE
		|					TT_Substitutes.Products = TT_UsedMaterials.Products
		|					AND TT_Substitutes.Characteristic = TT_UsedMaterials.Characteristic
		|					AND ISNULL(&QueryTextAnaloguePackingRatio, 1) * TT_Substitutes.NumberOfPackages 
		|						= ISNULL(&QueryTextMaterialPackingRatio, 1) * TT_UsedMaterials.NumberOfPackages)";
		
		Query.Text = StrReplace(Query.Text,
			"&QueryTextAnaloguePackingRatio",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TT_Substitutes.Package",
			"TT_Substitutes.Products"));
		
		Query.Text = StrReplace(Query.Text,
			"&QueryTextMaterialPackingRatio",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TT_UsedMaterials.Package",
			"TT_UsedMaterials.Products"));
		
		Query.SetParameter("UsedMaterials", UsedMaterials);
		Query.SetParameter("Substitutes", Substitutes);
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			
			MessageText = NStr("vi = 'Đã tìm thấy sự trùng lặp các tập hợp nguyên vật liệu và vật tư tương tự.';
								|ru = 'Обнаружено дублирование наборов материалов и аналогов.';
								|en = 'Duplicate substitute and material sets are found.'; fa = 'Duplicate substitute and material sets are found.';
								|it = 'Обнаружено дублирование наборов материалов и аналогов.';
								|pl = 'Duplicate substitute and material sets are found.';
								|tr = 'Malzeme ve ikame setlerinin kopyaları keşfedildi.'");
			Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure CheckDuplicatesOfScope(Cancel)
	
	MessageText = NStr("vi = 'Đã tìm thấy sự trùng lặp các dòng trong vùng thao tác.';
						|ru = 'Обнаружено дублирование строк в области действия.';
						|en = 'Duplicate lines are found in the scope.'; fa = 'Duplicate lines are found in the scope.';
						|it = 'Обнаружено дублирование строк в области действия.';
						|pl = 'Duplicate lines are found in the scope.';
						|tr = 'Kapsam alanı kümesinde satırların çoğaltılması tespit edildi.'");
	SetName = "AreasOfAction";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Set.LineOfBusiness AS LineOfBusiness,
	|	Set.Department AS Department,
	|	Set.Product AS Product,
	|	Set.ItemVariantOfProduct AS ItemVariantOfProduct,
	|	Set.ProductionOrder AS ProductionOrder,
	|	Set.BillOfMaterials AS BillOfMaterials,
	|	Set.Stage AS Stage,
	|	Set.SalesOrder AS SalesOrder,
	|	Set.LineNumber AS LineNumber
	|INTO TTSet
	|FROM
	|	&Set AS Set
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Set.LineNumber) AS LineNumber,
	|	Set.LineOfBusiness AS LineOfBusiness,
	|	Set.Department AS Department,
	|	Set.Product AS Product,
	|	Set.ItemVariantOfProduct AS ItemVariantOfProduct,
	|	Set.ProductionOrder AS ProductionOrder,
	|	Set.BillOfMaterials AS BillOfMaterials,
	|	Set.Stage AS Stage,
	|	Set.SalesOrder AS SalesOrder
	|FROM
	|	TTSet AS Set
	|
	|GROUP BY
	|	Set.ProductionOrder,
	|	Set.LineOfBusiness,
	|	Set.SalesOrder,
	|	Set.Stage,
	|	Set.BillOfMaterials,
	|	Set.ItemVariantOfProduct,
	|	Set.Product,
	|	Set.Department
	|
	|HAVING
	|	COUNT(DISTINCT Set.LineNumber) > 1";
	
	Query.SetParameter("Set", ThisObject[SetName]);
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Common.MessageToUser(
			MessageText,
			ThisObject,
			SetName + "[" + (Selection.LineNumber - 1) + "].LineOfBusiness",
			"Object",
			Cancel);
		
	EndDo;

EndProcedure

Procedure CheckIntersectionOfScope(Cancel, WriteMode)
	
	If WriteMode <> DocumentWriteMode.Posting
	 Or ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials Then
	
		Return;
	
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Set.LineOfBusiness AS LineOfBusiness,
	|	Set.Department AS Department,
	|	Set.Product AS Product,
	|	Set.ItemVariantOfProduct AS ItemVariantOfProduct,
	|	Set.ProductionOrder AS ProductionOrder,
	|	Set.BillOfMaterials AS BillOfMaterials,
	|	Set.Stage AS Stage,
	|	Set.SalesOrder AS SalesOrder
	|INTO DocumentScopes
	|FROM
	|	&ScopeSet AS Set
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Set.Products AS Products,
	|	Set.Characteristic AS Characteristic
	|INTO DocumentMaterials
	|FROM
	|	&SetOfMaterials AS Set
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AlternativeMaterials.Recorder AS Recorder,
	|	UsedMaterials.Products AS Products,
	|	UsedMaterials.Characteristic AS Characteristic
	|INTO CheckTable
	|FROM
	|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|		LEFT JOIN DocumentMaterials AS UsedMaterials
	|		ON (TRUE)
	|WHERE
	|	AlternativeMaterials.Recorder <> &Ref
	|	AND AlternativeMaterials.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				DocumentMaterials
	|			WHERE
	|				AlternativeMaterials.Products = DocumentMaterials.Products
	|				AND AlternativeMaterials.Characteristic = DocumentMaterials.Characteristic)
	|
	|INDEX BY
	|	Recorder,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PermissionToReplaceMaterialsMaterials.Ref AS Resolution
	|INTO ExcludedPermissions
	|FROM
	|	Document.EngineeringChangeOrder.UsedMaterials AS PermissionToReplaceMaterialsMaterials
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CheckTable AS CheckTable
	|			WHERE
	|				PermissionToReplaceMaterialsMaterials.Ref = CheckTable.Recorder)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					DocumentMaterials AS DocumentMaterials
	|				WHERE
	|					PermissionToReplaceMaterialsMaterials.Products = DocumentMaterials.Products
	|					AND PermissionToReplaceMaterialsMaterials.Characteristic = DocumentMaterials.Characteristic)
	|
	|UNION ALL
	|
	|SELECT
	|	CheckTable.Recorder
	|FROM
	|	CheckTable AS CheckTable
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Document.EngineeringChangeOrder.UsedMaterials AS PermissionToReplaceMaterialsMaterials
	|				WHERE
	|					PermissionToReplaceMaterialsMaterials.Ref = CheckTable.Recorder
	|					AND PermissionToReplaceMaterialsMaterials.Products = CheckTable.Products
	|					AND PermissionToReplaceMaterialsMaterials.Characteristic = CheckTable.Characteristic)
	|
	|INDEX BY
	|	Resolution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScopesOfSubstitutes.Resolution AS Resolution,
	|	ScopesOfSubstitutes.BillOfMaterials AS BillOfMaterials,
	|	ScopesOfSubstitutes.Stage AS Stage,
	|	ScopesOfSubstitutes.Department AS Department,
	|	ScopesOfSubstitutes.SalesOrder AS SalesOrder,
	|	ScopesOfSubstitutes.ProductionOrder AS ProductionOrder,
	|	ScopesOfSubstitutes.Product AS Product,
	|	ScopesOfSubstitutes.ItemVariantOfProduct AS ItemVariantOfProduct,
	|	ScopesOfSubstitutes.LineOfBusiness AS LineOfBusiness,
	|	ScopesOfSubstitutes.Resolution.ValidityStartDate AS ValidityStartDate,
	|	ScopesOfSubstitutes.Resolution.ValidityEndDate AS ValidityEndDate
	|INTO PermissionScopes
	|FROM
	|	InformationRegister.ScopesOfSubstitutes AS ScopesOfSubstitutes
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CheckTable AS CheckTable
	|			WHERE
	|				ScopesOfSubstitutes.Resolution = CheckTable.Recorder)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					ExcludedPermissions AS ExcludedPermissions
	|				WHERE
	|					ScopesOfSubstitutes.Resolution = ExcludedPermissions.Resolution)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PermissionScopes.Resolution AS Resolution,
	|	CASE
	|		WHEN PermissionScopes.ValidityEndDate = DATETIME(1, 1, 1)
	|				AND &ValidityEndDate = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		WHEN PermissionScopes.ValidityEndDate <> DATETIME(1, 1, 1)
	|				AND &ValidityEndDate <> DATETIME(1, 1, 1)
	|				AND (&ValidityStartDate BETWEEN PermissionScopes.ValidityStartDate AND PermissionScopes.ValidityEndDate
	|					OR &ValidityEndDate BETWEEN PermissionScopes.ValidityStartDate AND PermissionScopes.ValidityEndDate)
	|			THEN TRUE
	|		WHEN PermissionScopes.ValidityEndDate = DATETIME(1, 1, 1)
	|				AND &ValidityEndDate <> DATETIME(1, 1, 1)
	|				AND &ValidityEndDate >= PermissionScopes.ValidityStartDate
	|			THEN TRUE
	|		WHEN PermissionScopes.ValidityEndDate <> DATETIME(1, 1, 1)
	|				AND &ValidityEndDate = DATETIME(1, 1, 1)
	|				AND &ValidityStartDate <= PermissionScopes.ValidityEndDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsIntersectionByPeriod,
	|	CASE
	|		WHEN PermissionScopes.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN PermissionScopes.LineOfBusiness = DocumentAreasOfAction.LineOfBusiness
	|					OR DocumentAreasOfAction.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE PermissionScopes.LineOfBusiness <> DocumentAreasOfAction.LineOfBusiness
	|	END AS ThereIsIntersectionInDirectionOfActivity,
	|	CASE
	|		WHEN PermissionScopes.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN PermissionScopes.Department = DocumentAreasOfAction.Department
	|					OR DocumentAreasOfAction.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE PermissionScopes.Department <> DocumentAreasOfAction.Department
	|	END AS ThereIsIntersectionByDivision,
	|	CASE
	|		WHEN NOT PermissionScopes.ProductionOrder IN (VALUE(Document.ProductionOrder2_2.EmptyRef), 
	|														 UNDEFINED)
	|			THEN PermissionScopes.ProductionOrder = DocumentAreasOfAction.ProductionOrder
	|					OR DocumentAreasOfAction.ProductionOrder IN (VALUE(Document.ProductionOrder2_2.EmptyRef), 
	|														 UNDEFINED)
	|			ELSE PermissionScopes.ProductionOrder <> DocumentAreasOfAction.ProductionOrder 
	|				AND NOT DocumentAreasOfAction.ProductionOrder IN (VALUE(Document.ProductionOrder2_2.EmptyRef), 
	|														 UNDEFINED)
	|	END AS ThereIsIntersectionOnProductionOrder,
	|	CASE
	|		WHEN PermissionScopes.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
	|			THEN PermissionScopes.SalesOrder = DocumentAreasOfAction.SalesOrder
	|					OR DocumentAreasOfAction.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|		ELSE PermissionScopes.SalesOrder <> DocumentAreasOfAction.SalesOrder
	|	END AS ThereIsIntersectionOnClientSOrder,
	|	CASE
	|		WHEN PermissionScopes.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|			THEN DocumentAreasOfAction.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|					OR PermissionScopes.BillOfMaterials = DocumentAreasOfAction.BillOfMaterials
	|						AND (PermissionScopes.Stage = DocumentAreasOfAction.Stage
	|							OR PermissionScopes.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|								AND DocumentAreasOfAction.Stage = VALUE(Catalog.ProductionStages.EmptyRef))
	|		ELSE PermissionScopes.BillOfMaterials <> DocumentAreasOfAction.BillOfMaterials
	|	END AS ThereIsIntersectionAccordingToSpecification,
	|	CASE
	|		WHEN PermissionScopes.Product <> VALUE(Catalog.Products.EmptyRef)
	|			THEN DocumentAreasOfAction.Product = VALUE(Catalog.Products.EmptyRef)
	|					OR PermissionScopes.Product = DocumentAreasOfAction.Product
	|						AND (PermissionScopes.ItemVariantOfProduct = DocumentAreasOfAction.ItemVariantOfProduct
	|							OR PermissionScopes.ItemVariantOfProduct <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|								AND DocumentAreasOfAction.ItemVariantOfProduct = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|		ELSE PermissionScopes.Product <> DocumentAreasOfAction.Product
	|	END AS ThereIsIntersectionOnProduct,
	|	DocumentAreasOfAction.LineOfBusiness = PermissionScopes.LineOfBusiness
	|		AND DocumentAreasOfAction.Department = PermissionScopes.Department
	|		AND DocumentAreasOfAction.Product = PermissionScopes.Product
	|		AND DocumentAreasOfAction.ItemVariantOfProduct = PermissionScopes.ItemVariantOfProduct
	|		AND DocumentAreasOfAction.ProductionOrder = PermissionScopes.ProductionOrder
	|		AND DocumentAreasOfAction.BillOfMaterials = PermissionScopes.BillOfMaterials
	|		AND DocumentAreasOfAction.Stage = PermissionScopes.Stage
	|		AND DocumentAreasOfAction.SalesOrder = PermissionScopes.SalesOrder AS ThereIsIntersectionForAllAnalysts
	|INTO IntersectionTable
	|FROM
	|	DocumentScopes AS DocumentAreasOfAction
	|		INNER JOIN PermissionScopes AS PermissionScopes
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntersectionTable.Resolution AS Resolution,
	|	MAX(IntersectionTable.ThereIsIntersectionInDirectionOfActivity) AS ThereIsIntersectionInDirectionOfActivity,
	|	MAX(IntersectionTable.ThereIsIntersectionByDivision) AS ThereIsIntersectionByDivision,
	|	MAX(IntersectionTable.ThereIsIntersectionOnProductionOrder) AS ThereIsIntersectionOnProductionOrder,
	|	MAX(IntersectionTable.ThereIsIntersectionOnClientSOrder) AS ThereIsIntersectionOnClientSOrder,
	|	MAX(IntersectionTable.ThereIsIntersectionAccordingToSpecification) AS ThereIsIntersectionAccordingToSpecification,
	|	MAX(IntersectionTable.ThereIsIntersectionOnProduct) AS ThereIsIntersectionOnProduct,
	|	MAX(IntersectionTable.ThereIsIntersectionForAllAnalysts) AS ThereIsIntersectionForAllAnalysts
	|FROM
	|	IntersectionTable AS IntersectionTable
	|WHERE
	|	IntersectionTable.ThereIsIntersectionByPeriod
	|	AND (IntersectionTable.ThereIsIntersectionForAllAnalysts
	|			OR IntersectionTable.ThereIsIntersectionInDirectionOfActivity
	|			OR IntersectionTable.ThereIsIntersectionByDivision
	|			OR IntersectionTable.ThereIsIntersectionOnProductionOrder
	|			OR IntersectionTable.ThereIsIntersectionOnClientSOrder
	|			OR IntersectionTable.ThereIsIntersectionAccordingToSpecification
	|			OR IntersectionTable.ThereIsIntersectionOnProduct)
	|
	|GROUP BY
	|	IntersectionTable.Resolution";
	
	Query.SetParameter("ScopeSet", AreasOfAction);
	Query.SetParameter("SetOfMaterials", UsedMaterials);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ValidityStartDate", ValidityStartDate);
	Query.SetParameter("ValidityEndDate", ValidityEndDate);
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	If ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute Then
		
		MessageTemplate = NStr("vi = 'Đã tìm thấy sự giao thoa vùng hiệu lực (%1) với chứng từ %2, cấm giao thoa đối với thay thế ưu tiên.';
								|ru = 'Обнаружено пересечение области действия (%1) с документом %2, для приоритетных замен пересечения запрещены.';
								|en = 'Scope intersection (%1) with the %2 document is detected. Intersections are prohibited for priority replacements.'; fa = 'Scope intersection (%1) with the %2 document is detected. Intersections are prohibited for priority replacements.';
								|it = 'Scope intersection (%1) with the %2 document is detected. Intersections are prohibited for priority replacements.';
								|pl = 'Scope intersection (%1) with the %2 document is detected. Intersections are prohibited for priority replacements.';
								|tr = '( %1 ) etki alanının,  %2 belgesi ile çakıştığı tespit edildi. Öncelikli değiştirmelerde çakışmalara izin verilmez.'");
		
	EndIf;
	
	While Selection.Next() Do
		
		ArrayOfIntersectionFields = New Array;
		If Selection.ThereIsIntersectionForAllAnalysts Then
			FieldText = NStr("vi = 'tất cả mục tin';
							|ru = 'все реквизиты';
							|en = 'all attributes'; fa = 'all attributes';
							|it = 'all attributes';
							|pl = 'all attributes';
							|tr = 'tüm öznitelikler'");
			ArrayOfIntersectionFields.Add(FieldText);
		Else
			
			If Selection.ThereIsIntersectionInDirectionOfActivity Then
				FieldText = NStr("vi = 'lĩnh vực hoạt động';
								|ru = 'направление деятельности';
								|en = 'line of business'; fa = 'line of business';
								|it = 'line of business';
								|pl = 'line of business';
								|tr = 'iş kolu'");
				ArrayOfIntersectionFields.Add(FieldText);
			EndIf;
			
			If Selection.ThereIsIntersectionByDivision Then
				FieldText = NStr("vi = 'bộ phận';
								|ru = 'подразделение';
								|en = 'business unit'; fa = 'واحد تجاری';
								|it = 'business unit';
								|pl = 'business unit';
								|tr = 'departman'");
				ArrayOfIntersectionFields.Add(FieldText);
			EndIf;
			
			If Selection.ThereIsIntersectionOnProductionOrder Then
				FieldText = NStr("vi = 'đơn hàng sản xuất';
								|ru = 'заказ на производство';
								|en = 'production order'; fa = 'production order';
								|it = 'ordine di produzione';
								|pl = 'zlecenie produkcyjne';
								|tr = 'üretim emri'");
				ArrayOfIntersectionFields.Add(FieldText);
			EndIf;
			
			If Selection.ThereIsIntersectionOnClientSOrder Then
				FieldText = NStr("vi = 'đơn hàng của khách';
								|ru = 'заказ клиента';
								|en = 'sales order'; fa = 'sales order';
								|it = 'ordine del cliente';
								|pl = 'zamówienie klienta';
								|tr = 'müşteri siparişi'");
				ArrayOfIntersectionFields.Add(FieldText);
			EndIf;
			
			If Selection.ThereIsIntersectionAccordingToSpecification Then
				FieldText = NStr("vi = 'bảng kê chi tiết';
								|ru = 'спецификация';
								|en = 'bill of materials'; fa = 'bill of materials';
								|it = 'bill of materials';
								|pl = 'bill of materials';
								|tr = 'ürün reçetesi'");
				ArrayOfIntersectionFields.Add(FieldText);
			EndIf;
			
			If Selection.ThereIsIntersectionOnProduct Then
				FieldText = NStr("vi = 'sản phẩm';
								|ru = 'изделие';
								|en = 'finished product'; fa = 'finished product';
								|it = 'finished product';
								|pl = 'finished product';
								|tr = 'nihai ürün'");
				ArrayOfIntersectionFields.Add(FieldText);
			EndIf;
			
		EndIf;
		
		IntersectionText = StrConcat(ArrayOfIntersectionFields, ", ");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, IntersectionText, Selection.Resolution);
		Common.MessageToUser(MessageText,,,, Cancel);
	
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
