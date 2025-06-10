package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	fmt.Println("Starting eventhub front-end...")
	// logging setup
	timeStampStr := fmt.Sprintf("%d", time.Now().Unix())
	logFilePath := "/tmp/event-hub_" + timeStampStr + ".log"
	logFile, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatalf("error opening log file: %v", err)
	}
	defer logFile.Close()

	// Create a logger that writes to the MultiWriter
	multiWriter := io.MultiWriter(os.Stdout, logFile)

	logger := log.New(multiWriter, "", log.Ldate|log.Ltime|log.Lshortfile)
	logger.Print("starting event-hub...")

	// database setup
	//db.InitDB()

	// gin engine setup
	ginServer := gin.Default()
	//ginServer.LoadHTMLGlob()

	// Middleware to add logger to the context
	ginServer.Use(func(c *gin.Context) {
		c.Set("logger", logger)
		c.Next()
	})

	// Serve static files from the "public" directory
	ginServer.Static("/static", "./front-end")

	// // Serve the index page at the root URL
	// ginServer.GET("/", func(c *gin.Context) {
	// 	c.File("./front-end/index.html")
	// })

	// Serve the signup page at the /signup URL
	ginServer.GET("/signup", func(c *gin.Context) {
		c.File("./front-end/user-signup.html")
	})

	ginServer.GET("/login", func(c *gin.Context) {
		c.File("./front-end/user-login.html")
	})

	ginServer.GET("/event-list", func(c *gin.Context) {
		c.File("./front-end/events.html")
	})

	ginServer.GET("/registered-event-list", func(c *gin.Context) {
		c.File("./front-end/user-registered-events.html")
	})

	ginServer.GET("/user-dashboard", func(c *gin.Context) {
		c.File("./front-end/user-dashboard.html")
	})

	ginServer.GET("/event-create", func(c *gin.Context) {
		c.File("./front-end/event-create.html")
	})

	ginServer.Run(":8000") //localhost:8080
}
