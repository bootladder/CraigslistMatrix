package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/mmcdole/gofeed"
)

// TableModel is the model that is sent to the front end
type TableModel struct {
	Name         string        `json:"name"`
	ID           int           `json:"id"`
	TopHeadings  []string      `json:"topHeadings"`
	SideHeadings []string      `json:"sideHeadings"`
	Rows         [][]CellModel `json:"rows"`
}

//CellModel models a RSS feed
type CellModel struct {
	FeedURL          string `json:"feedUrl"`
	PageURL          string `json:"pageUrl"`
	Hits             int    `json:"hits"`
	LinksAlreadySeen []string
}

func editTableModelField(tableID, fieldIndex int, fieldValue, fieldType string) {
	tableModel := getTableModelByID(tableID)

	if fieldType == "top" {
		tableModel.TopHeadings[fieldIndex] = fieldValue
	} else if fieldType == "side" {
		tableModel.SideHeadings[fieldIndex] = fieldValue
	} else {
		fmt.Print("NO FIELD TYPE SUPPLIED. DOING NOTHING")
	}

	tableModel.Rows = make([][]CellModel, len(tableModel.SideHeadings))
	for i := range tableModel.Rows {
		tableModel.Rows[i] = make([]CellModel, len(tableModel.TopHeadings))

		for j := range tableModel.Rows[i] {
			tableModel.Rows[i][j].FeedURL = makeCraigslistFeedURL(tableModel.SideHeadings[i], tableModel.TopHeadings[j])
			tableModel.Rows[i][j].PageURL = makeCraigslistPageURL(tableModel.SideHeadings[i], tableModel.TopHeadings[j])
			tableModel.Rows[i][j].Hits = -1
		}
	}

	writeTable(tableModel, tableID)
}

func makeCraigslistFeedURL(side, top string) string {
	return "https://" + top + ".craigslist.org/search/jjj?format=rss&query=" + side
}

func makeCraigslistPageURL(side, top string) string {
	return "https://" + top + ".craigslist.org/search/jjj?query=" + side
}

func (t *TableModel) toJSONBytes(tableID int) []byte {
	//don't allow out of bounds tableIDs
	filename := fmt.Sprintf("../data/table%d.json", tableID)

	contents, err := ioutil.ReadFile(filename)
	fatal(err)
	return contents
}

func updateTableData(tableID int) {

	fp := gofeed.NewParser()

	tableModel := getTableModelByID(tableID)

	for i := range tableModel.Rows {
		for j := range tableModel.Rows[i] {
			feedURL := tableModel.Rows[i][j].FeedURL

			feed, _ := fp.ParseURL(feedURL)
			//fmt.Println(feed.Title)
			fmt.Printf("There are %d items\n", len(feed.Items))

			var numberOfUnseenLinks = 0
			for _, item := range feed.Items {
				fmt.Print(item.Title)
				if false == sliceContains(tableModel.Rows[i][j].LinksAlreadySeen, item.Link) {
					numberOfUnseenLinks++
				}
			}
			fmt.Printf("There are %d UNSEEN items\n", numberOfUnseenLinks)

			tableModel.Rows[i][j].Hits = numberOfUnseenLinks

			tableModel.Rows[i][j].LinksAlreadySeen = make([]string, len(feed.Items))
			for z, item := range feed.Items {
				tableModel.Rows[i][j].LinksAlreadySeen[z] = item.Link
			}

		}
	}

	writeTable(tableModel, tableID)
}

func sliceContains(slice []string, elem string) bool {
	for i := range slice {
		if slice[i] == elem {
			return true
		}
	}
	return false
}

func addTopField(tableID int) {

	// TODO: populate table model rows
	tableModel := getTableModelByID(tableID)
	tableModel.TopHeadings = append(tableModel.TopHeadings, "new field")
	writeTable(tableModel, tableID)
}

func addSideField(tableID int) {
	tableModel := getTableModelByID(tableID)
	tableModel.SideHeadings = append(tableModel.SideHeadings, "new field")
	tableModel.Rows =
		append(tableModel.Rows, make([]CellModel, len(tableModel.TopHeadings)))

	writeTable(tableModel, tableID)
}

func deleteTopField(tableID int) {
	tableModel := getTableModelByID(tableID)
	tableModel.TopHeadings = tableModel.TopHeadings[:len(tableModel.TopHeadings)-1]

	//keep the rows in sync by slicing to length of top headers
	for i := range tableModel.Rows {
		tableModel.Rows[i] = tableModel.Rows[i][:len(tableModel.TopHeadings)]
	}

	writeTable(tableModel, tableID)
}

func deleteSideField(tableID int) {
	tableModel := getTableModelByID(tableID)

	// keep the rows and the side headings in sync
	tableModel.SideHeadings = tableModel.SideHeadings[:len(tableModel.SideHeadings)-1]
	tableModel.Rows = tableModel.Rows[:len(tableModel.SideHeadings)]

	writeTable(tableModel, tableID)
}

func openTableID(tableID int) io.Reader {
	//don't allow out of bounds tableIDs
	filename := fmt.Sprintf("../data/table%d.json", tableID)
	fileReader, err := os.Open(filename)
	fatal(err)
	return fileReader
}

func writeTable(tableModel TableModel, tableID int) {
	filename := fmt.Sprintf("../data/table%d.json", tableID)

	jsonBytes, _ := json.MarshalIndent(tableModel, "", "  ")
	ioutil.WriteFile(filename, jsonBytes, 666)
}

func getTableModelByID(tableID int) TableModel {

	fileReader := openTableID(tableID)

	var tableModel TableModel
	err = json.NewDecoder(fileReader).Decode(&tableModel)
	return tableModel
}

func JSONListOfTableNames() []byte {

	return []byte("durr")
}
