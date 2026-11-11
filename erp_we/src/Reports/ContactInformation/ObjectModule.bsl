#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region DataOutput

Procedure OutputDataToTable(Result, StructureOfReportGeneration, ReportTable)
	
	ReportTable.Clear();
	Template = GetTemplate("DataOutput");
	
	EmptyStringArea = Template.GetArea("IsBlankString|PartnerDetails");
	ReportTable.Put(EmptyStringArea);
	HeaderArea_ = Template.GetArea("Title");
	ScopeOfApplication_3     = Template.GetArea("Filter");
	ScopeOfApplication_3.Parameters.TextSelectionByPartners = StructureOfReportGeneration.FilterPresentation;
	
	If StructureOfReportGeneration.GroupByPartner Then
		
		HeaderArea_.Parameters.TitleText = NStr("vi = 'Thông tin liên hệ của người liên hệ';
												|ru = 'Контактная информация контактных лиц';
												|en = 'Contact details of contact persons'; fa = 'Contact details of contact persons';
												|it = 'Contatti';
												|pl = 'Dane kontaktowe osób kontaktowych';
												|tr = 'İlgili kişilerin iletişim bilgileri'");
		ReportTable.Put(HeaderArea_);
		ReportTable.Put(EmptyStringArea);
		ReportTable.StartRowGroup("Filter");
		ReportTable.Put(ScopeOfApplication_3,2);
		ReportTable.EndRowGroup();
		ReportTable.Put(EmptyStringArea);
		DisplayReportHeaderWithDimensions(StructureOfReportGeneration, ReportTable, Template);
		OutputDataToReportWithDimensions(Result, StructureOfReportGeneration, ReportTable, Template);
		
		ReportTable.FixedTop = 5;
		
	Else
		
		HeaderArea_.Parameters.TitleText = NStr("vi = 'Thông tin liên hệ theo bạn hàng';
												|ru = 'Контактная информация по партнерам';
												|en = 'Contact details by partners'; fa = 'اطلاعات تماس بر اساس شرکا';
												|it = 'Recapiti dei partner';
												|pl = 'Informacje kontaktowe na temat partnerów';
												|tr = 'İş ortakları iletişim bilgileri'");
		ReportTable.Put(HeaderArea_);
		ReportTable.Put(EmptyStringArea);
		ReportTable.StartRowGroup("Filter");
		ReportTable.Put(ScopeOfApplication_3,2);
		ReportTable.EndRowGroup();
		ReportTable.Put(EmptyStringArea);
		DisplayReportHeader(StructureOfReportGeneration, ReportTable, Template);
		OutputDataToReport(Result, StructureOfReportGeneration, ReportTable, Template);
		ReportTable.FixedLeft  = 1;
		ReportTable.FixedTop = 5;
		
	EndIf;
	
EndProcedure

Procedure DisplayReportHeader(StructureOfReportGeneration, ReportTable, Template)
	
	PartnerDetailsHeaderArea              = Template.GetArea("Header|PartnerDetails");
	AreaDimensionHeaderPartnerDetails   = Template.GetArea("HeaderGrouping|PartnerDetails");
	
	BorderNoLine = New Line(SpreadsheetDocumentCellLineType.None);
	BorderIsSolidLine    = New Line(SpreadsheetDocumentCellLineType.Solid);

	NumberOfPartnerData = StructureOfReportGeneration.SelectedPartnerFields.FindRows(New Structure("Check",True)).Count() + 1;
	
	AreaDimensionHeaderPartnerDetails.Parameters.HeaderPartnerData =NStr("vi = 'Dữ liệu bạn hàng';
																		|ru = 'Данные партнера';
																		|en = 'Partner data'; fa = 'Partner data';
																		|it = 'Dati partner';
																		|pl = 'Dane partnera';
																		|tr = 'İş ortağı verileri'");
	If NumberOfPartnerData > 1 Then
		AreaDimensionHeaderPartnerDetails.Areas.HeaderPartnerData.RightBorder = BorderNoLine;
	EndIf;
	ReportTable.Put(AreaDimensionHeaderPartnerDetails);
	
	Indus = 2;
	For Each String In StructureOfReportGeneration.SelectedPartnerFields Do
		
		If Not String.Check Then
			Continue;
		EndIf;
		
		AreaDimensionHeaderPartnerDetails.Areas.HeaderPartnerData.LeftBorder = BorderNoLine;
		
		If Indus <> NumberOfPartnerData Then
			AreaDimensionHeaderPartnerDetails.Areas.HeaderPartnerData.RightBorder = BorderNoLine;
		Else
			AreaDimensionHeaderPartnerDetails.Areas.HeaderPartnerData.RightBorder = BorderIsSolidLine;
		EndIf;
		
		AreaDimensionHeaderPartnerDetails.Parameters.HeaderPartnerData = "";
		ReportTable.Join(AreaDimensionHeaderPartnerDetails);
		
		Indus = Indus + 1;
		
	EndDo;
	
	AreaRoleHeader = Template.GetArea("HeaderRoleKL");
	AreaRoleHeader.Areas.HeaderRoleKL.BottomBorder = BorderNoLine;
	For Each String In StructureOfReportGeneration.CPRoles Do
		
		 If Not String.Check Then
			Continue;
		EndIf;
		
		AreaRoleHeader.Parameters.Value = String.Presentation;
		ReportTable.Join(AreaRoleHeader);
		
	EndDo;
	
	AreaDimensionHeaderPartnerDetails.Areas.HeaderPartnerData.RightBorder = BorderIsSolidLine;
	AreaDimensionHeaderPartnerDetails.Parameters.HeaderPartnerData =NStr("vi = 'Tên gọi làm việc';
																		|ru = 'Рабочее наименование';
																		|en = 'Working title'; fa = 'عنوان کاری';
																		|it = 'Nome operativo';
																		|pl = 'Nazwa robocza';
																		|tr = 'İş ünvanı'");
	ReportTable.Put(AreaDimensionHeaderPartnerDetails);
	
	For Each String In StructureOfReportGeneration.SelectedPartnerFields Do
		
		If Not String.Check Then
			Continue;
		EndIf;
		
		AreaDimensionHeaderPartnerDetails.Parameters.HeaderPartnerData = String.Presentation;
		ReportTable.Join(AreaDimensionHeaderPartnerDetails);
		
	EndDo;
	
	AreaRoleHeader.Areas.HeaderRoleKL.BottomBorder  = BorderIsSolidLine;
	AreaRoleHeader.Areas.HeaderRoleKL.TopBorder = BorderNoLine;
	For Each String In StructureOfReportGeneration.CPRoles Do
		
		If Not String.Check Then
			Continue;
		EndIf;
		
		AreaRoleHeader.Parameters.Value = "";
		ReportTable.Join(AreaRoleHeader);
		
	EndDo;

EndProcedure

Procedure OutputDataToReport(Result, StructureOfReportGeneration, ReportTable, Template)
	
	ArrayOfSelectedPartnerFields  = New Array;
	PartnerSKiArray              = New Array;
	RolesArray                   = New Array;
	NumberOfSelectedCycles       = StructureOfReportGeneration.SelectedCICP.FindRows(New Structure("Check", True)).Count();
	PartnerDetailsField = Template.GetArea("PartnerDetailsString|PartnerDetails");
	ScopeAndRoleOfCL           = Template.GetArea("LineRoleKL");
	
	For Each String In StructureOfReportGeneration.SelectedPartnerFields Do
		
		If Not String.Check Then
			Continue;
		EndIf;
		
		If TypeOf(String.Value) = Type("CatalogRef.ContactInformationKinds") Then
			PartnerSKiArray.Add(String.Value);
		Else
			ArrayOfSelectedPartnerFields.Add(String.Value);
		EndIf;
		
	EndDo;
	
	ThereIsKiPartner = (PartnerSKiArray.Count() > 0);
	ThereIsClassification = (ArrayOfSelectedPartnerFields.Find("Classification") <> Undefined);
	
	For Each String In StructureOfReportGeneration.CPRoles Do
		
		If Not String.Check Then
			Continue;
		EndIf;
		
		RolesArray.Add(String.Value);
		
	EndDo;
	
	ThereIsDataOnRoles = RolesArray.Count() > 0;
	
	SamplePartners = Result.Select(QueryResultIteration.ByGroups);
	While SamplePartners.Next() Do
		
		PartnerDetailsField.Parameters.Value = SamplePartners.PartnerName;
		PartnerDetailsField.Parameters.DetailsValue = SamplePartners.PartnerLink;
		ReportTable.Put(PartnerDetailsField);
		
		For Each Item In ArrayOfSelectedPartnerFields Do
			
			If Item <> "Classification" Then
				If Item = "RegistrationDate" Then
					PartnerDetailsField.Parameters.Value = Format(SamplePartners[Item],"DLF=D");
				Else
					PartnerDetailsField.Parameters.Value = SamplePartners[Item];
				EndIf;
				PartnerDetailsField.Parameters.DetailsValue = SamplePartners.PartnerLink;
				ReportTable.Join(PartnerDetailsField);
			EndIf;
			
		EndDo;
		
		If ThereIsClassification Then
			
			SamplingClassification = SamplePartners.Select(QueryResultIteration.ByGroups);
			While SamplingClassification.Next() Do
			
				PartnerDetailsField.Parameters.Value = SamplingClassification.Classification;
				PartnerDetailsField.Parameters.DetailsValue = SamplePartners.PartnerLink;
				ReportTable.Join(PartnerDetailsField);
			
			EndDo;
			
		EndIf;
		
		If ThereIsKiPartner Then
			
			If ThereIsClassification Then
				SamplingClassification.Reset();
				SamplingClassification.Next();
				PartnerCISelection = SamplingClassification.Select(QueryResultIteration.ByGroups);
			Else
				PartnerCISelection = SamplePartners.Select(QueryResultIteration.ByGroups);
			EndIf;
			
			PartnerSCurColumn = 0;
			
			While PartnerCISelection.Next() Do
				
				PutInColumn = PartnerSKiArray.Find(PartnerCISelection.PartnerSKiType);
				If PutInColumn = Undefined Then
					SamplingPresentationOfCI = Undefined;
					Continue;
				EndIf;
				
				While PartnerSCurColumn < PutInColumn Do
					PartnerDetailsField.Parameters.Value = "";
					ReportTable.Join(PartnerDetailsField);
					PartnerSCurColumn = PartnerSCurColumn + 1;
				EndDo;
				
				SamplingPresentationOfCI = PartnerCISelection.Select(QueryResultIteration.ByGroups);
				PartnerSCIPresentation = "";
				While SamplingPresentationOfCI.Next() Do
					PartnerSCIPresentation = PartnerSCIPresentation
					                          + ?(IsBlankString(PartnerSCIPresentation),"", Chars.LF)
					                          + SamplingPresentationOfCI.PartnerSCIPresentation;
				EndDo;
				
				PartnerDetailsField.Parameters.Value = PartnerSCIPresentation;
				ReportTable.Join(PartnerDetailsField);
				PartnerSCurColumn = PartnerSCurColumn + 1;
				
			EndDo;
			
			While PartnerSCurColumn < PartnerSKiArray.Count() Do
				PartnerDetailsField.Parameters.Value = "";
				ReportTable.Join(PartnerDetailsField);
				PartnerSCurColumn = PartnerSCurColumn + 1;
			EndDo;
			
		EndIf;
		
		If ThereIsDataOnRoles Then
			
			If ThereIsKiPartner Then
				If SamplingPresentationOfCI = Undefined Then
					PartnerCISelection.Reset();
					PartnerCISelection.Next();
					SamplingPresentationOfCI = PartnerCISelection.Select(QueryResultIteration.ByGroups);
					SamplingPresentationOfCI.Next();
					RoleSelection = SamplingPresentationOfCI.Select(QueryResultIteration.ByGroups);
				Else
					SamplingPresentationOfCI.Reset();
					SamplingPresentationOfCI.Next();
					RoleSelection = SamplingPresentationOfCI.Select(QueryResultIteration.ByGroups);
				EndIf;
			Else
				If ThereIsClassification Then
					SamplingClassification.Reset();
					SamplingClassification.Next();
					RoleSelection = SamplingClassification.Select(QueryResultIteration.ByGroups);
				Else
					RoleSelection = SamplePartners.Select(QueryResultIteration.ByGroups);
				EndIf;
			EndIf;
			
			CurColumnNumberRoles = 1;
			
			While RoleSelection.Next() Do
				
					RoleNumberInArray = RolesArray.Find(?(RoleSelection.ContactRole = NULL, Catalogs.RolesOfPartnerContactPersons.EmptyRef(), RoleSelection.ContactRole));
					If RoleNumberInArray = Undefined Then
						Continue;
					Else
						ColumnNumberToFillIn = RoleNumberInArray + 1;
					EndIf;
					
					TextRole = "";
					
					SampleCL = RoleSelection.Select(QueryResultIteration.ByGroups);
					While SampleCL.Next() Do
						
						CLText = "";
						NameOfKL = "";
						
						If SampleCL.KLLink = NULL Then
							Continue;
						EndIf;
						
						SamplingTypesOfKIKL = SampleCL.Select(QueryResultIteration.ByGroups);
						While SamplingTypesOfKIKL.Next() Do
							
							DetailsSelection = SamplingTypesOfKIKL.Select();
							While DetailsSelection.Next() Do
								NameOfKL = DetailsSelection.KLName_ + ":";
								If Not IsBlankString(DetailsSelection.KicklPresentation) Then
									CLText = CLText + Chars.LF + Chars.Tab +  DetailsSelection.KicklView + ": " + DetailsSelection.KicklPresentation;
								EndIf;
							EndDo;
							
						EndDo;
						
						TextRole = TextRole +?(IsBlankString(TextRole),"", Chars.LF)+ NameOfKL + CLText;
						
					EndDo;
					
					While CurColumnNumberRoles < ColumnNumberToFillIn Do
						ScopeAndRoleOfCL.Parameters.Value = "";
						ReportTable.Join(ScopeAndRoleOfCL);
						CurColumnNumberRoles = CurColumnNumberRoles + 1;
					EndDo;
					
					ScopeAndRoleOfCL.Parameters.Value = TextRole;
					ReportTable.Join(ScopeAndRoleOfCL);
					CurColumnNumberRoles = CurColumnNumberRoles + 1;
					
			EndDo;
			
			While CurColumnNumberRoles < RolesArray.Count() + 1 Do
				ScopeAndRoleOfCL.Parameters.Value = "";
				ReportTable.Join(ScopeAndRoleOfCL);
				CurColumnNumberRoles = CurColumnNumberRoles + 1;
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OutputDataToReportWithDimensions(Result, StructureOfReportGeneration, ReportTable, Template)
	
	AreaPartnerGroupingString   = Template.GetArea("PartnerGroupingString");
	AreaPartnerGroupingKiString = Template.GetArea("PartnerGroupingKiString");
	AreaStringPropsCL           = Template.GetArea("PropsKLString");
	AreaStringKIPCL                = Template.GetArea("KicklString");
	
	BorderNoLine      = New Line(SpreadsheetDocumentCellLineType.None);
	BorderIsSolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	
	KicklArray          = New Array;
	For Each TableRow In StructureOfReportGeneration.SelectedCICP Do
	
		If Not TableRow.Check Then
			Continue;
		EndIf;
		
		KicklArray.Add(TableRow.Value);
	
	EndDo;
	NumberOfKiColumns = KicklArray.Count();
	
	SamplePartners = Result.Select(QueryResultIteration.ByGroups);
	While SamplePartners.Next() Do
		
		AreaPartnerGroupingString.Parameters.Value = SamplePartners.PartnerName;
		AreaPartnerGroupingString.Parameters.DetailsValue = SamplePartners.PartnerLink;
		If NumberOfKiColumns > 0 Then
			AreaPartnerGroupingString.Areas.PartnerGroupingString.RightBorder = BorderNoLine;
		EndIf;
		ReportTable.Put(AreaPartnerGroupingString);
		
		OutputColumnNumber = 1;
		If NumberOfKiColumns > 0 Then
			
			While OutputColumnNumber < NumberOfKiColumns + 1 Do
				
				If OutputColumnNumber < NumberOfKiColumns Then
					AreaPartnerGroupingKiString.Areas.PartnerGroupingKiString.RightBorder  = BorderNoLine;
				Else
					AreaPartnerGroupingKiString.Areas.PartnerGroupingKiString.RightBorder  = BorderIsSolidLine;
				EndIf;
				
				AreaPartnerGroupingKiString.Parameters.DetailsValue = SamplePartners.PartnerLink;
				ReportTable.Join(AreaPartnerGroupingKiString);
				OutputColumnNumber = OutputColumnNumber + 1;
			EndDo;
			
		EndIf;
		
		If NumberOfKiColumns > 0 Then
			
			ReportTable.StartRowGroup("PartnerSCL");
			
			SampleCL = SamplePartners.Select(QueryResultIteration.ByGroups);
			
			While SampleCL.Next() Do 
				
				If SampleCL.KLLink = NULL Then
					Continue;
				EndIf;
				
				LineKL           = SampleCL.KLLink;
				RoleRow         = "";
				JobTitleOnBusinessCard = "";
				
				RoleSelection = SampleCL.Select(QueryResultIteration.ByGroups);
				While RoleSelection.Next() Do
					
					If RoleSelection.ContactRole <> NULL Then
						RoleRow = RoleRow + ?(IsBlankString(RoleRow),"",Chars.LF) + RoleSelection.ContactRole;
					EndIf;
					SamplingTypesOfKIKL = RoleSelection.Select(QueryResultIteration.ByGroups);
					While SamplingTypesOfKIKL.Next() Do
						
						If SamplingTypesOfKIKL.KicklView = NULL Then
							Break;
						EndIf;
						
						KicklText = "";
						DetailsSelection = SamplingTypesOfKIKL.Select();
						While DetailsSelection.Next() Do
							KicklText = KicklText + ?(IsBlankString(KicklText),"",Chars.LF)+ DetailsSelection.KicklView + ": " + DetailsSelection.KicklPresentation;
							JobTitleOnBusinessCard = DetailsSelection.JobTitleOnBusinessCard;
						EndDo;
						
					EndDo;
					
				EndDo;
				
				AreaStringPropsCL.Parameters.ContactPerson      = LineKL;
				AreaStringPropsCL.Parameters.Roles                = RoleRow;
				AreaStringPropsCL.Parameters.JobTitleOnBusinessCard  = JobTitleOnBusinessCard;
				AreaStringPropsCL.Parameters.DetailsValue = SampleCL.KLLink;
				ReportTable.Put(AreaStringPropsCL,2);
				
				CurrentColumnNumber = 1;
				SamplingTypesOfKIKL.Reset();
				While SamplingTypesOfKIKL.Next() Do
					
					KiPresentation = "";
					If SamplingTypesOfKIKL.KicklView = NULL Then
						Break;
					EndIf;
					
					DetailsSelection = SamplingTypesOfKIKL.Select();
					KiPresentation = "";
					While DetailsSelection.Next() Do
						KiPresentation = KiPresentation + ?(IsBlankString(KiPresentation), "", Chars.LF) + DetailsSelection.KicklPresentation;
					EndDo;
					
					ColumnNumberToFillIn = KicklArray.Find(SamplingTypesOfKIKL.KicklView) + 1;
					
					While CurrentColumnNumber < ColumnNumberToFillIn Do
						AreaStringKIPCL.Parameters.Value = "";
						ReportTable.Join(AreaStringKIPCL);
						CurrentColumnNumber = CurrentColumnNumber + 1;
					EndDo;
					
					AreaStringKIPCL.Parameters.Value = KiPresentation;
					ReportTable.Join(AreaStringKIPCL);
					CurrentColumnNumber = CurrentColumnNumber + 1;
					
				EndDo;
				
				While CurrentColumnNumber < NumberOfKiColumns + 1 Do
					AreaStringKIPCL.Parameters.Value = "";
					ReportTable.Join(AreaStringKIPCL);
					CurrentColumnNumber = CurrentColumnNumber + 1;
				EndDo;
				
			EndDo;
			
			ReportTable.EndRowGroup();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DisplayReportHeaderWithDimensions(StructureOfReportGeneration, ReportTable, Template)
	
	PartnerHeaderArea     = Template.GetArea("PartnerHeader_");
	KLHeaderArea          = Template.GetArea("KICKLECap");
	AreaHeaderAccountDetails = Template.GetArea("HeaderDetailsKL");
	
	BorderNoLine      = New Line(SpreadsheetDocumentCellLineType.None);
	BorderIsSolidLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	
	KicklArray          = New Array;
	For Each TableRow In StructureOfReportGeneration.SelectedCICP Do
	
		If Not TableRow.Check Then
			Continue;
		EndIf;
		
		KicklArray.Add(TableRow.Value);
	
	EndDo;
	ColumnsCount = KicklArray.Count();
	
	ReportTable.Put(PartnerHeaderArea);
	
	OutputColumnNumber = 1;
	If ColumnsCount > 0 Then
		While OutputColumnNumber < ColumnsCount + 1 Do
			
			If OutputColumnNumber = 1 Then 
				KLHeaderArea.Parameters.Value = NStr("vi = 'Thông tin liên hệ';
													|ru = 'Контактная информация';
													|en = 'Contact details'; fa = 'اطلاعات تماس';
													|it = 'Informazioni di contatto';
													|pl = 'Dane kontaktowe';
													|tr = 'İletişim bilgileri'");
			Else
				KLHeaderArea.Parameters.Value = "";
			EndIf;
			
			If OutputColumnNumber < ColumnsCount Then
				KLHeaderArea.Areas.KICKLECap.RightBorder  = BorderNoLine;
			Else
				KLHeaderArea.Areas.KICKLECap.RightBorder  = BorderIsSolidLine;
			EndIf;
			
			If OutputColumnNumber > 1 Then
				KLHeaderArea.Areas.KICKLECap.LeftBorder  = BorderNoLine;
			Else
				KLHeaderArea.Areas.KICKLECap.LeftBorder  = BorderIsSolidLine;
			EndIf;
			
			ReportTable.Join(KLHeaderArea);
			OutputColumnNumber = OutputColumnNumber + 1;
		EndDo;
		
		KLHeaderArea.Areas.KICKLECap.LeftBorder  = BorderIsSolidLine;
		
	EndIf;
	
	ReportTable.Put(AreaHeaderAccountDetails);
	
	OutputColumnNumber = 1;
	If ColumnsCount > 0 Then
		For Each Item In KicklArray Do
			KLHeaderArea.Parameters.Value = Item;
			ReportTable.Join(KLHeaderArea);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region RequestFormationAndExecution

Function QueryResultBasedOnReportData(StructureOfReportGeneration)
	
	MatchingRequestParametersForAITypes = New Map;
	
	If Not StructureOfReportGeneration.GroupByPartner Then
		QueryTextSelectedPartnerFields = QueryTextSelectedPartnerFields(StructureOfReportGeneration.SelectedPartnerFields);
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	Partners.Ref AS PartnerLink,
	|	Partners.Description AS PartnerName" + QueryTextSelectedPartnerFields + "%PartnerCIFields%" +"%ClassificationField%" +"%KLFields%
	|FROM
	|	Catalog.Partners AS Partners" +"%PartnerCIConnection%"+ "%ConnectionOfCLRole%" + "%CompoundClassification%
	|WHERE
	|Partners.Ref IN
	|		(SELECT
	|			FilterByPartners.Partner
	|		FROM
	|			FilterByPartners AS FilterByPartners)
	|
	|ORDER BY
	|  PartnerName"  + "%ArrangePartnerSKi%" + "%OrderingString%
	|TOTALS BY
	|	PartnerLink" + "%ResultsClassification%" + "%PartnerSCIResults%";
	
	AddClassificationDataToRequest(Query,StructureOfReportGeneration);
	AddPartnerCIDataToRequest(Query.Text,StructureOfReportGeneration, MatchingRequestParametersForAITypes);
	AddOutputOfPartnerCIFieldsToRequest(Query.Text,StructureOfReportGeneration, MatchingRequestParametersForAITypes.Count() > 0);
	
	AddContactDetailsToRequest(Query.Text,StructureOfReportGeneration,MatchingRequestParametersForAITypes);
	AddSelectionToRequest(Query);
	
	For Each Parameter In MatchingRequestParametersForAITypes Do
		
		Query.SetParameter(Parameter.Key,Parameter.Value);
		
	EndDo;
	
	Return Query.Execute();
	
EndFunction

Procedure AddClassificationDataToRequest(Query,StructureOfReportGeneration)

	ClassificationCompoundText = "";
	TextClassificationField       = "";
	TextualClassification      = "";
	
	If StructureOfReportGeneration.GroupByPartner 
		Or Not (AccessRight("View", Metadata.InformationRegisters.ABCXYZCustomerClassification)) Then 
		ThereIsClassificationOutput = False;
	Else
		ThereIsClassificationOutput = StructureOfReportGeneration.SelectedPartnerFields.FindRows(New Structure("Value,Check","Classification",True)).Count() > 0;
	EndIf;
	
	If ThereIsClassificationOutput Then
		
		TextualClassification = ",
		|Classification";
		
		ClassificationCompoundText = "
		|LEFT JOIN InformationRegister.ABCXYZCustomerClassification.SliceLast(
		|		,
		|		ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Revenue)
		|			AND ClassificationType = VALUE(Enum.TypesOfClassification.ABC)) AS ABCSliceLast
		|ON ABCSliceLast.Partner = Partners.Ref
		|LEFT JOIN InformationRegister.ABCXYZCustomerClassification.SliceLast(
		|		,
		|		ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Revenue)
		|			AND ClassificationType = VALUE(Enum.TypesOfClassification.XYZ)) AS XYZSliceLast
		|ON XYZSliceLast.Partner = Partners.Ref";
		
		TextClassificationField       = ",
		|CASE
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.AClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.XClass)
		|	THEN &AX
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.AClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.YClass)
		|	THEN &AY
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.AClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.ZClass)
		|	THEN &AZ
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.BClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.XClass)
		|	THEN &BX
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.BClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.YClass)
		|	THEN &BY
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.BClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.ZClass)
		|	THEN &BZ
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.CClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.XClass)
		|	THEN &CX
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.CClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.YClass)
		|	THEN &CY
		|WHEN ABCSliceLast.Class = VALUE(Enum.ABCClassification.CClass)
		|		AND XYZSliceLast.Class = VALUE(Enum.XYZClassification.ZClass)
		|	THEN &CZ
		|ELSE &NotClassified
		|END AS Classification";
		
		Query.SetParameter("AX","AX");
		Query.SetParameter("AY","AY");
		Query.SetParameter("AZ","AZ");
		Query.SetParameter("BX","BX");
		Query.SetParameter("BY","BY");
		Query.SetParameter("BZ","BZ");
		Query.SetParameter("CX","CX");
		Query.SetParameter("CY","CY");
		Query.SetParameter("CZ","CZ");
		Query.SetParameter("NotClassified",NStr("vi = 'Chưa phân loại';
												|ru = 'Не классифицирован';
												|en = 'Not classified'; fa = 'طبقه‌بندی‌نشده';
												|it = 'Non classificato';
												|pl = 'Nie sklasyfikowany';
												|tr = 'Sınıflandırılmadı'"));
	
	EndIf;
	
	Query.Text = StrReplace(Query.Text,"%CompoundClassification%",ClassificationCompoundText);
	Query.Text = StrReplace(Query.Text,"%ClassificationField%",TextClassificationField);
	Query.Text = StrReplace(Query.Text,"%ResultsClassification%",TextualClassification);

EndProcedure

Procedure AddSelectionToRequest(Query)

	SchemeForSelectingPartners = GetTemplate("FilterByPartners");
	
	TemplateComposer = New DataCompositionTemplateComposer();
	DataCompositionTemplate = TemplateComposer.Execute(SchemeForSelectingPartners, SettingsComposer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));

	QueryTextFilter = DataCompositionTemplate.DataSets.Main.Query;
	
	For Each Parameter In DataCompositionTemplate.ParameterValues Do
		If Parameter.Name = "AXLine" Then
			Query.Parameters.Insert("AXLine", NStr("vi = 'AX';
													|ru = 'AX';
													|en = 'AX'; fa = 'AX';
													|it = 'AX';
													|pl = 'AX';
													|tr = 'AX'"));
		ElsIf Parameter.Name = "AYLine" Then
			Query.Parameters.Insert("AYLine", NStr("vi = 'AY';
													|ru = 'AY';
													|en = 'AY'; fa = 'AY';
													|it = 'AY';
													|pl = 'AY';
													|tr = 'AY'"));
		ElsIf Parameter.Name = "AZLine" Then
			Query.Parameters.Insert("AZLine", NStr("vi = 'AZ';
													|ru = 'AZ';
													|en = 'AZ'; fa = 'AZ';
													|it = 'AZ';
													|pl = 'AZ';
													|tr = 'AZ'"));
		ElsIf Parameter.Name = "BXLine" Then
			Query.Parameters.Insert("BXLine", NStr("vi = 'BX';
													|ru = 'BX';
													|en = 'BX'; fa = 'BX';
													|it = 'BX';
													|pl = 'BX';
													|tr = 'BX'"));
		ElsIf Parameter.Name = "LineBY" Then
			Query.Parameters.Insert("LineBY", NStr("vi = 'BY';
													|ru = 'BY';
													|en = 'BY'; fa = 'BY';
													|it = 'BY';
													|pl = 'BY';
													|tr = 'BY'"));
		ElsIf Parameter.Name = "BZLine" Then
			Query.Parameters.Insert("BZLine", NStr("vi = 'BZ';
													|ru = 'BZ';
													|en = 'BZ'; fa = 'BZ';
													|it = 'BZ';
													|pl = 'BZ';
													|tr = 'BZ'"));
		ElsIf Parameter.Name = "CXLine" Then
			Query.Parameters.Insert("CXLine", NStr("vi = 'CX';
													|ru = 'CX';
													|en = 'CX'; fa = 'CX';
													|it = 'CX';
													|pl = 'CX';
													|tr = 'CX'"));
		ElsIf Parameter.Name = "CYLine" Then
			Query.Parameters.Insert("CYLine", NStr("vi = 'CY';
													|ru = 'CY';
													|en = 'CY'; fa = 'CY';
													|it = 'CY';
													|pl = 'CY';
													|tr = 'CY'"));
		ElsIf Parameter.Name = "CZLine" Then
			Query.Parameters.Insert("CZLine", NStr("vi = 'CZ';
													|ru = 'CZ';
													|en = 'CZ'; fa = 'CZ';
													|it = 'CZ';
													|pl = 'CZ';
													|tr = 'CZ'"));
		ElsIf Parameter.Name = "LineNotClassified" Then
			Query.Parameters.Insert("LineNotClassified", NStr("vi = 'Chưa phân loại';
																|ru = 'Не классифицирован';
																|en = 'Not classified'; fa = 'طبقه‌بندی‌نشده';
																|it = 'Non classificato';
																|pl = 'Nie sklasyfikowany';
																|tr = 'Sınıflandırılmadı'"));
		Else
			Query.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndIf;
	EndDo;
	
	QueryTextFilter = QueryTextFilter +"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	FoundItemFROM = StrFind(QueryTextFilter,"FROM");
	If FoundItemFROM <> 0 Then
		QueryTextFilter = Left(QueryTextFilter,FoundItemFROM - 1) + "  INTO FilterByPartners
		|  " + Right(QueryTextFilter,StrLen(QueryTextFilter) - FoundItemFROM + 1);
		
	EndIf;
	
	Query.Text = QueryTextFilter + Query.Text;

EndProcedure

Procedure AddContactDetailsToRequest(QueryText, StructureOfReportGeneration,MatchingRequestParametersForAITypes)
	
	ConditionTextByRole   = "(";
	TermsAndConditionsForCITypes = "(";
	StringOr             = " OR ";
	StringLengthOr        = StrLen(StringOr);
	
	For Each RoleRow In StructureOfReportGeneration.CPRoles Do
		
		If (Not RoleRow.Check ) Then
			
			Continue;
			
		EndIf;
		
		If RoleRow.Value = Catalogs.RolesOfPartnerContactPersons.EmptyRef() Then
			RequestParameterStringRole = "IS NULL";
		Else
			RequestParameterStringRole = " = &RoleOfCL" + String(MatchingRequestParametersForAITypes.Count() + 1);
			MatchingRequestParametersForAITypes.Insert("RoleOfCL" + String(MatchingRequestParametersForAITypes.Count() + 1),RoleRow.Value);
		EndIf;
		
		ConditionTextByRole = ConditionTextByRole + "
				|		ContactPersonsOfPartnersRoleOfContactPerson.ContactRole " + RequestParameterStringRole + StringOr;
				
	EndDo;
	
	StringFunctionsClientServer.DeleteLastCharInString(ConditionTextByRole, StringLengthOr);
	ConditionTextByRole = ConditionTextByRole + ")";
		
	For Each CIRow In StructureOfReportGeneration.SelectedCICP Do
		
		If CIRow.Check Then
			
			RequestParameterString = "CIKind" + String(MatchingRequestParametersForAITypes.Count() + 1);
			MatchingRequestParametersForAITypes.Insert(RequestParameterString, CIRow.Value);
			
			TermsAndConditionsForCITypes = TermsAndConditionsForCITypes + "
			|	 ContactPersonsOfPartnersContactInformation.Kind = &" + RequestParameterString + StringOr;
			
		EndIf;
		
	EndDo;
	
	StringFunctionsClientServer.DeleteLastCharInString(TermsAndConditionsForCITypes, StringLengthOr);
	TermsAndConditionsForCITypes = TermsAndConditionsForCITypes + ")";
		
	If StrLen(ConditionTextByRole) = 1 Then
		QueryText = StrReplace(QueryText,"%KLFields%","");
		QueryText = StrReplace(QueryText,"%OrderingString%","");
		QueryText = StrReplace(QueryText,"%ConnectionOfCLRole%","");
		Return;
	EndIf;
	
	ConditionTextByRole = ConditionTextByRole + "	AND ContactPersonsForPartners.Owner IN
		|	(SELECT
		|		FilterByPartners.Partner
		|	FROM
		|		FilterByPartners AS FilterByPartners)";
		
	QueryTextAdditionalOrdering = ",
	|ContactRole,
	|KicklView
	|";
	
	QueryText = StrReplace(QueryText,"%OrderingString%",QueryTextAdditionalOrdering);
	
	RequestTextSelectedContactPersonFields = ",
	|ContactPersonsOfCIRole.ContactRole AS ContactRole,
	|ContactPersonsOfCIRole.Kind AS KicklView,
	|ContactPersonsOfCIRole.Presentation AS KicklPresentation,
	|ContactPersonsOfCIRole.JobTitleOnBusinessCard AS JobTitleOnBusinessCard,
	|ContactPersonsOfCIRole.Description AS KLName_,
	|ContactPersonsOfCIRole.Ref AS KLLink";
	
	QueryText = StrReplace(QueryText,"%KLFields%", RequestTextSelectedContactPersonFields);
	
	RequestTextByCL = "
	|SELECT ALLOWED
	|	ContactPersonsForPartners.Ref,
	|	ContactPersonsForPartners.Description,
	|	ContactPersonsForPartners.JobTitleOnBusinessCard,
	|	ContactPersonsOfPartnersRoleOfContactPerson.ContactRole,
	|	ContactPersonsOfPartnersContactInformation.Kind,
	|	ContactPersonsOfPartnersContactInformation.Presentation,
	|	ContactPersonsForPartners.Owner
	|INTO ContactPersonsOfCIRole
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactPersonRoles AS ContactPersonsOfPartnersRoleOfContactPerson
	|		ON (ContactPersonsOfPartnersRoleOfContactPerson.Ref = ContactPersonsForPartners.Ref)
	|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
	|		ON (ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref) AND &ConditionByCIType 
	|WHERE &ConditionForRoles
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	RequestTextByCL = StrReplace(RequestTextByCL, "&ConditionByCIType", TermsAndConditionsForCITypes);
	RequestTextByCL = StrReplace(RequestTextByCL, "&ConditionForRoles", ConditionTextByRole);
	
	QueryText = RequestTextByCL + QueryText; 
	
	RequestTextConnectionContactPersonsRolesKeys = " 
	|LEFT JOIN ContactPersonsOfCIRole AS ContactPersonsOfCIRole
	|	ON Partners.Ref = ContactPersonsOfCIRole.Owner";
	
	QueryText = StrReplace(QueryText,"%ConnectionOfCLRole%",RequestTextConnectionContactPersonsRolesKeys);
	
	RequestTextTotalsByRole = ",
	|ContactRole,
	|KLLink,
	|KicklView";
	
	If StructureOfReportGeneration.GroupByPartner Then
		RequestTextTotalsByRole = ",
		|KLLink,
		|ContactRole,
		|KicklView";
	Else
		RequestTextTotalsByRole = ",
		|ContactRole,
		|KLLink,
		|KicklView";
	EndIf;
	
	QueryText = QueryText + RequestTextTotalsByRole;
	
EndProcedure

Procedure AddOutputOfPartnerCIFieldsToRequest(QueryText, StructureOfReportGeneration, ThereIsKiPartner)
	
	If ThereIsKiPartner And Not StructureOfReportGeneration.GroupByPartner Then
		
		ReplacementText = ",
		|	PartnersContactInformation.Kind AS PartnerSKiType,
		|	PartnersContactInformation.Presentation AS PartnerSCIPresentation";
		
	Else
		
		ReplacementText = ""
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"%PartnerCIFields%", ReplacementText);
	
EndProcedure

Function QueryTextSelectedPartnerFields(SelectedPartnerFields)
	
	QueryTextSelectedPartnerFields = "";
	
	For Each String In SelectedPartnerFields Do
		
		If TypeOf(String.Value) = Type("CatalogRef.ContactInformationKinds") Or String.Value = "Classification" Then
			Break;
		EndIf;
		
		If Not String.Check Then
			Continue;
		EndIf;
		
		QueryTextSelectedPartnerFields = QueryTextSelectedPartnerFields + ", " + Chars.LF + "	Partners." + String.Value + " AS " + String.Value;
		
	EndDo;
	
	Return QueryTextSelectedPartnerFields;
	
EndFunction

Procedure AddPartnerCIDataToRequest(QueryText, StructureOfReportGeneration, MatchingRequestParametersForAITypes)
	
	TextOfPartnerSCIConnection    = "";
	QueryTextPartnerSCIResults  = "";
	SortTextByPartnerKi = "";
	StringOr                    = " OR ";
	
	If Not StructureOfReportGeneration.GroupByPartner Then
		
		For Each String In StructureOfReportGeneration.SelectedPartnerFields Do
			
			If TypeOf(String.Value) = Type("String") Or Not String.Check Then
				Continue;
			EndIf;
			
			RequestParameterString = "CIKind" + String(MatchingRequestParametersForAITypes.Count() + 1);
			MatchingRequestParametersForAITypes.Insert(RequestParameterString,String.Value); 
			TextOfPartnerSCIConnection = TextOfPartnerSCIConnection + "PartnersContactInformation.Kind = &" + RequestParameterString + StringOr;
			
		EndDo;
		
		If Not IsBlankString(TextOfPartnerSCIConnection) Then
			
			StringFunctionsClientServer.DeleteLastCharInString(TextOfPartnerSCIConnection, StrLen(StringOr));
			TextOfPartnerSCIConnection = "
			|	LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
			|		ON (PartnersContactInformation.Ref = Partners.Ref) AND (" + TextOfPartnerSCIConnection + ")";
			
			QueryTextPartnerSCIResults = ",
			|	PartnerSKiType,
			|	PartnerSCIPresentation";
			
			SortTextByPartnerKi =",
			|	PartnerSKiType";
			
		EndIf;
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"%PartnerCIConnection%",TextOfPartnerSCIConnection);
	QueryText = StrReplace(QueryText,"%PartnerSCIResults%",QueryTextPartnerSCIResults);
	QueryText = StrReplace(QueryText,"%ArrangePartnerSKi%",SortTextByPartnerKi);
	
EndProcedure

#EndRegion

#Region Other

Procedure GenerateReport(ReportTable, StructureOfReportGeneration)  Export
	
	Result = QueryResultBasedOnReportData(StructureOfReportGeneration);
	OutputDataToTable(Result, StructureOfReportGeneration, ReportTable);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf