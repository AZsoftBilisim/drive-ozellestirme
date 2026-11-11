#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer;
Var CurFlowOfLinkReplacement; // DataProcessorObject.ExportImportDataReferenceReplacementStream

#EndRegion

#Region Internal

Procedure Initialize(Container, LinkReplacementFlow) Export
	
	CurContainer = Container;
	CurFlowOfLinkReplacement = LinkReplacementFlow;
	
EndProcedure

Procedure ReCreateLinks() Export
	
	FilesOfReCreatedLinks = CurContainer.GetFilesFromDirectory(ExportImportDataInternal.ReferenceRebuilding());
	For Each FileOfReCreatedLinks In FilesOfReCreatedLinks Do
		
		SourceLinks = CurContainer.ReadObjectFromFile(FileOfReCreatedLinks); // Array of AnyRef
		
		For Each SourceRef1 In SourceLinks Do
			
			XMLTypeName1 = ExportImportDataInternal.XMLRefType(SourceRef1);
			FullObjectName = SourceRef1.Metadata().FullName(); 
			NewRef = Common.ObjectManagerByFullName(FullObjectName).GetRef();
			
			CurFlowOfLinkReplacement.ReplaceRef(XMLTypeName1, String(SourceRef1.UUID()), String(NewRef.UUID()), True);
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
