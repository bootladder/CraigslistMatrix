module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Json.Decode exposing (..)


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { urlSetId : Int
    , debugBreadcrumb : String
    , currentUrl : String
    , myTableModel : TableModel
    }


type alias CellViewModel =
    { color : String
    , label : String
    , url : String
    , hits : Int
    }

type alias TableModel =
    { name : String
    , topHeadings : List (String)
    , sideHeadings : List (String)
    , rows : List (List (CellViewModel))
    }

myTableTopHeadings : List (String)
myTableTopHeadings = ["sfbay", "boston", "newyork", "longisland", "austin", "seattle"]

myTableSideHeadings : List (String)
myTableSideHeadings = ["Carpentry", "Masonry", "Welding"]

buildCraigslistUrl : String -> String -> String
buildCraigslistUrl city query =
    "https://" ++ city ++ ".craigslist.org/d/jobs/search/jjj" ++ "?query= " ++ query

buildRowCells : List (String) -> String -> List (CellViewModel)
buildRowCells topHeadings query =
    List.map 
    (\h -> CellViewModel "blueCell" "1"  (buildCraigslistUrl h query) 0)
    topHeadings

myTableRows : List (List (CellViewModel))
myTableRows = 
    List.map
        (\sideHeading -> buildRowCells myTableTopHeadings sideHeading)
    myTableSideHeadings


myTableModel : TableModel
myTableModel = TableModel "Table 1" myTableTopHeadings myTableSideHeadings myTableRows 

-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    -- The initial model comes from a Request, now it is hard coded
    ( Model
        0
        "dummy debug"
        "https://google.com"
        myTableModel
    , Cmd.none
    )



-- UPDATE


type Msg
    = FormInput String
    | AddColumnButtonClicked
    | CellClicked CellViewModel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellClicked cellViewModel -> 
            ( {model 
                | currentUrl = cellViewModel.url
                }
            , Cmd.none
            )
        _ ->
            ( model
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [id "container"] 
    [ div [id "nothing"] [ text "nothing"]
    , tableNameLabel myTableModel.name
    , topLabel
    , sideLabel
    , constantsLabel
    , div [id "myTable"] [renderTable myTableModel]
    , div [id "urlView"] [text model.currentUrl]
    ]

renderTable : TableModel -> Html Msg
renderTable tableModel =
    let
        pairs = List.map2 Tuple.pair tableModel.sideHeadings tableModel.rows

        renderedRows = List.map 
                        (\(heading, cells) -> renderRow heading cells)
                        pairs
    in
    table [] (
        [renderTableHeadersRow tableModel.topHeadings]
        ++
        renderedRows
    )

renderTableHeadersRow : List (String) -> Html Msg
renderTableHeadersRow headings  =
    tr [] (
            [ th [] [text  "///"] ]
            ++
            List.map (\s -> th [] [text s]) headings
    )

renderRow : String -> List (CellViewModel) ->  Html Msg
renderRow heading cellViewModels =
        tr [id "myRow"] ( 
                th [] [text heading]
                ::
                  List.map renderCellViewModel cellViewModels
            )

renderCellViewModel : CellViewModel -> Html Msg
renderCellViewModel cellViewModel =
    td [class cellViewModel.color, onClick (CellClicked cellViewModel)] [text cellViewModel.label]


tableNameLabel : String -> Html msg
tableNameLabel name =
        div [id "tableNameLabel"]
            [ text "table name label"
            , div [] [text name]
            ]

constantsLabel : Html msg
constantsLabel = 
        div [id "constantsLabel"] 
            [ text "constants label" 
            , div [] [text "jobs"]
            ]

sideLabel : Html msg
sideLabel = 
        div [id "sideLabel"] 
        [ text "side label" 
        , div [] [text "search query"]
        ]


topLabel : Html msg
topLabel = 
        div [id "topLabel"] 
        [ text "top label" 
        , div [] [text "cities"]
        ]


-- DECODER

type alias TestModel =
    {
        a : String
        ,b : String
        ,c : Int
        ,d : List (String)
        ,e : List (List (String))
    }

--type alias TableModel =
--    { name : String
--    , rows : List (List (CellViewModel))
--    , topHeadings : List (String)
--    , sideHeadings : List (String)
--    }


backendResponseDecoder : Decoder TableModel
backendResponseDecoder = 
    Json.Decode.map4 TableModel
        nameDecoder 
        topHeadingsDecoder 
        sideHeadingsDecoder 
        rowsDecoder 

nameDecoder : Decoder String
nameDecoder =
  Json.Decode.field "name" Json.Decode.string

rowsDecoder : Decoder (List (List (CellViewModel)))
rowsDecoder =
  Json.Decode.field "rows" (Json.Decode.list ((Json.Decode.list cellViewModelDecoder)))

cellViewModelDecoder : Decoder CellViewModel
cellViewModelDecoder =
    Json.Decode.map4 CellViewModel
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "label" Json.Decode.string)
        (Json.Decode.field "color" Json.Decode.string)
        (Json.Decode.field "hits" Json.Decode.int)


topHeadingsDecoder : Decoder (List (String))
topHeadingsDecoder =
  Json.Decode.field "topHeadings" (Json.Decode.list string)

sideHeadingsDecoder : Decoder (List (String))
sideHeadingsDecoder =
  Json.Decode.field "sideHeadings" (Json.Decode.list string)

